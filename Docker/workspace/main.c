#include <stdio.h>
#include <pcap.h>
#include <netinet/ip.h>
#include <netinet/if_ether.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include "packet_queue.h"

#define CYCLES_PER_PACKET 10

uint64_t total_cycles = 0;
PacketQueue queue;

void packet_handler(u_char *args, const struct pcap_pkthdr *header, const u_char *packet) {
    struct ethhdr *eth = (struct ethhdr *)packet;

    if (ntohs(eth->h_proto) != ETH_P_IP)
        return;

    struct iphdr *ip = (struct iphdr *)(packet + sizeof(struct ethhdr));
    struct in_addr src_addr, dst_addr;
    src_addr.s_addr = ip->saddr;
    dst_addr.s_addr = ip->daddr;

    printf("Packet: %s -> %s | Proto: %u | Length: %d\n",
           inet_ntoa(src_addr),
           inet_ntoa(dst_addr),
           ip->protocol,
           header->len);

    enqueue(&queue, header->ts.tv_usec, packet, header->len);

}

void process_packets() {
uint64_t ts;
u_char *packet_data;
int packet_len;

while (dequeue(&queue, &ts, &packet_data, &packet_len)) {
    total_cycles += CYCLES_PER_PACKET;
    printf("Processed packet at timestamp %lu, total cycles = %lu, length = %d\n",
           ts, total_cycles, packet_len);

    printf("Packet data (hex): ");
// for (int i = 0; i < packet_len; i++) {
//     printf("%02X ", packet_data[i]);
//     if ((i + 1) % 16 == 0) printf("\n");  // new line every 16 bytes
// }
fwrite(packet_data, 1, packet_len, stdout);
printf("\n");

    // Deep Packet Inspection to be updated
     
    free(packet_data);
}

}

int main() {
    init_queue(&queue);

    char errbuf[PCAP_ERRBUF_SIZE];
    pcap_t *handle;
    struct bpf_program fp;
    char filter_exp[] = "ip and not src host 192.168.10.1 and not dst host 192.168.10.1";
    bpf_u_int32 net = 0;

    handle = pcap_create("ens3", errbuf);
    if (!handle) {
        fprintf(stderr, "Error creating pcap handle: %s\n", errbuf);
        return 1;
    }

    pcap_set_immediate_mode(handle, 1);
    pcap_set_snaplen(handle, 65535);
    pcap_set_promisc(handle, 1);
    pcap_set_timeout(handle, 100);
    int status = pcap_activate(handle);
    if (status != 0) {
        fprintf(stderr, "Error activating pcap handle: %s\n", pcap_statustostr(status));
        return 1;
    }

    if (pcap_compile(handle, &fp, filter_exp, 0, net) == -1) {
        fprintf(stderr, "Error compiling filter: %s\n", pcap_geterr(handle));
        return 1;
    }

    if (pcap_setfilter(handle, &fp) == -1) {
        fprintf(stderr, "Error setting filter: %s\n", pcap_geterr(handle));
        return 1;
    }

    pcap_loop(handle, 100, packet_handler, NULL);
    pcap_close(handle);

    process_packets();
    return 0;
}
