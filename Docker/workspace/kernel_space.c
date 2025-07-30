// SPDX-License-Identifier: GPL-2.0
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/skbuff.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>
#include <linux/hashtable.h>
#include <linux/jiffies.h>
#include <linux/slab.h>
#include <linux/workqueue.h>
#include <linux/string.h>
#include <linux/inet.h>

#define FLOW_TIMEOUT (5 * HZ)
#define DUMP_BYTES 32

MODULE_LICENSE("GPL");
MODULE_AUTHOR("VirtShield");
MODULE_DESCRIPTION("Hardware-inspired Flow Classifier with Deep Packet Inspection");

struct flow_key {
    __be32 saddr;
    __be32 daddr;
    __be16 sport;
    __be16 dport;
    __u8 proto;
};

struct flow_entry {
    struct flow_key key;
    unsigned long last_seen;
    u64 packets;
    u64 bytes;
    bool dpi_matched;
    struct hlist_node hnode;
};

static DEFINE_HASHTABLE(flow_table, 10); // 1024 buckets
static struct nf_hook_ops nfho;
static struct delayed_work flow_printer_work;

static const unsigned char DPI_PATTERN_BYTES[] = {
    0x5E, 0x00, 0x08
};
#define DPI_PATTERN_LEN (sizeof(DPI_PATTERN_BYTES))

static u32 flow_hash(const struct flow_key *key) {
    return jhash(key, sizeof(struct flow_key), 0);
}

static bool flow_key_equal(const struct flow_key *a, const struct flow_key *b) {
    return a->saddr == b->saddr && a->daddr == b->daddr &&
           a->sport == b->sport && a->dport == b->dport &&
           a->proto == b->proto;
}

static struct flow_entry *find_or_create_flow(const struct flow_key *key) {
    struct flow_entry *entry;
    struct hlist_node *tmp;
    u32 hash = flow_hash(key);

    hash_for_each_possible_safe(flow_table, entry, tmp, hnode, hash) {
        if (flow_key_equal(&entry->key, key)) {
            entry->last_seen = jiffies;
            return entry;
        }
    }

    entry = kmalloc(sizeof(*entry), GFP_ATOMIC);
    if (!entry)
        return NULL;

    entry->key = *key;
    entry->last_seen = jiffies;
    entry->packets = 0;
    entry->bytes = 0;
    entry->dpi_matched = false;
    hash_add(flow_table, &entry->hnode, hash);

    return entry;
}

static void print_flow_table(struct work_struct *work) {
    struct flow_entry *entry;
    int bkt;

    printk(KERN_INFO "VirtShield: --- Flow Table Snapshot ---\n");
    hash_for_each(flow_table, bkt, entry, hnode) {
        printk(KERN_INFO "VirtShield: %pI4:%u -> %pI4:%u | Proto: %u | Packets: %llu | Bytes: %llu | DPI: %s\n",
               &entry->key.saddr, ntohs(entry->key.sport),
               &entry->key.daddr, ntohs(entry->key.dport),
               entry->key.proto, entry->packets, entry->bytes,
               entry->dpi_matched ? "MATCH" : "none");
    }

    schedule_delayed_work(&flow_printer_work, 10 * HZ);
}

static void dump_packet_data(const unsigned char *data, unsigned int len) {
    char buf[3 * DUMP_BYTES + 1] = {0};
    unsigned int i, off = 0;

    len = min(len, (unsigned int)DUMP_BYTES);
    for (i = 0; i < len && off < sizeof(buf) - 3; i++)
        off += snprintf(buf + off, sizeof(buf) - off, "%02X ", data[i]);

    printk(KERN_INFO "VirtShield: Payload (first %u bytes): %s\n", len, buf);
}

static bool perform_dpi(struct sk_buff *skb, const struct iphdr *iph) {
    unsigned char *data;
    unsigned int data_len;

    if (skb_linearize(skb) != 0)
        return false;

    data = skb_transport_header(skb);
    if (iph->protocol == IPPROTO_TCP)
        data += tcp_hdrlen(skb);
    else if (iph->protocol == IPPROTO_UDP)
        data += sizeof(struct udphdr);
    else
        return false;

    data_len = skb_tail_pointer(skb) - data;
    if (data_len < DPI_PATTERN_LEN)
        return false;

    dump_packet_data(data, data_len);

    if (memcmp(data, DPI_PATTERN_BYTES, DPI_PATTERN_LEN) == 0)
        return true;

    return false;
}

static unsigned int nf_hook_fn(void *priv, struct sk_buff *skb, const struct nf_hook_state *state) {
    struct iphdr *iph;
    struct flow_key key = {};
    struct flow_entry *entry;
    u32 payload_len;

    if (!skb)
        return NF_ACCEPT;

    iph = ip_hdr(skb);
    if (!iph || (iph->protocol != IPPROTO_TCP && iph->protocol != IPPROTO_UDP))
        return NF_ACCEPT;

    // Filter only packets from client IP
    if (iph->saddr != in_aton("192.168.10.4"))
        return NF_ACCEPT;

    key.saddr = iph->saddr;
    key.daddr = iph->daddr;
    key.proto = iph->protocol;

    if (iph->protocol == IPPROTO_TCP) {
        struct tcphdr *tcph = tcp_hdr(skb);
        key.sport = tcph->source;
        key.dport = tcph->dest;
    } else if (iph->protocol == IPPROTO_UDP) {
        struct udphdr *udph = udp_hdr(skb);
        key.sport = udph->source;
        key.dport = udph->dest;
    }

    entry = find_or_create_flow(&key);
    if (!entry)
        return NF_ACCEPT;

    payload_len = skb->len - (iph->ihl * 4);
    entry->packets++;
    entry->bytes += payload_len;

    if (!entry->dpi_matched && perform_dpi(skb, iph)) {
        entry->dpi_matched = true;
        printk(KERN_INFO "VirtShield: DPI pattern matched for flow %pI4:%u -> %pI4:%u\n",
               &key.saddr, ntohs(key.sport), &key.daddr, ntohs(key.dport));
    }

    return NF_ACCEPT;
}

static int __init flow_classifier_init(void) {
    printk(KERN_INFO "VirtShield: Flow classifier module with DPI loaded\n");

    nfho.hook = nf_hook_fn;
    nfho.pf = PF_INET;
    nfho.hooknum = NF_INET_PRE_ROUTING;  // Capture only incoming packets
    nfho.priority = NF_IP_PRI_FIRST;

    INIT_DELAYED_WORK(&flow_printer_work, print_flow_table);
    schedule_delayed_work(&flow_printer_work, 10 * HZ);

    return nf_register_net_hook(&init_net, &nfho);
}

static void __exit flow_classifier_exit(void) {
    struct flow_entry *entry;
    struct hlist_node *tmp;
    int bkt;

    nf_unregister_net_hook(&init_net, &nfho);
    cancel_delayed_work_sync(&flow_printer_work);

    hash_for_each_safe(flow_table, bkt, tmp, entry, hnode) {
        hash_del(&entry->hnode);
        kfree(entry);
    }

    printk(KERN_INFO "VirtShield: Flow classifier module with DPI unloaded\n");
}

module_init(flow_classifier_init);
module_exit(flow_classifier_exit);
