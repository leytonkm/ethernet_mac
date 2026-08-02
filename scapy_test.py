from scapy.all import ARP, Ether, sniff

def handle(pkt):
    if pkt.haslayer(ARP) and pkt[ARP].op == 1:  # op 1 = request
        reply = Ether(dst=pkt[Ether].src) / ARP(
            op=2,
            hwsrc="02:00:00:00:00:01",
            psrc=pkt[ARP].pdst,
            hwdst=pkt[ARP].hwsrc,
            pdst=pkt[ARP].psrc
        )
        print("Built reply:", reply.summary())

sniff(filter="arp", prn=handle, count=5)