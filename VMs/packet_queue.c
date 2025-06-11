#include "packet_queue.h"
#include <string.h>

void init_queue(PacketQueue *q) {
    q->front = q->rear = NULL;
}

void enqueue(PacketQueue *q, uint64_t timestamp, const u_char *packet_data, int packet_len) {
    PacketNode *new_node = (PacketNode *)malloc(sizeof(PacketNode));
    new_node->timestamp = timestamp;
    new_node->packet_len = packet_len;
    new_node->packet_data = (u_char *)malloc(packet_len);
    memcpy(new_node->packet_data, packet_data, packet_len);
    new_node->next = NULL;

    if (q->rear == NULL) {
        q->front = q->rear = new_node;
        return;
    }

    q->rear->next = new_node;
    q->rear = new_node;
}

int dequeue(PacketQueue *q, uint64_t *timestamp, u_char **packet_data, int *packet_len) {
    if (q->front == NULL)
        return 0;

    PacketNode *temp = q->front;
    *timestamp = temp->timestamp;
    *packet_len = temp->packet_len;
    *packet_data = temp->packet_data;  
    q->front = q->front->next;

    if (q->front == NULL)
        q->rear = NULL;

    free(temp);  // Only free the node, NOT the packet_data (caller will free it)
    return 1;
}

int is_queue_empty(PacketQueue *q) {
    return q->front == NULL;
}
