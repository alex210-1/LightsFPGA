import socket

UDP_IP = "192.168.42.69"
UDP_PORT = 57345  # 274  # not sure which
MESSAGE = "RGB"  # * (255 * 255)


s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)

for i in range(3):
    s.sendto(MESSAGE.encode('utf-8'), (UDP_IP, UDP_PORT))
    print("\n\n 1. Client Sent : ", MESSAGE, "\n\n")
    data, address = s.recvfrom(4096)
    print("\n\n 2. Client received : ", data.decode('utf-8'), "\n\n")
