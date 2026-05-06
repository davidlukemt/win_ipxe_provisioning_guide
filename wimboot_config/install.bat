wpeutil InitializeNetwork
ipconfig /all
ping -n 11 127.0.0.1
ipconfig /all
netsh interface ip set address name="Ethernet 2" static <BM_Instance_IP> 255.255.255.255 <BM_Instance_Gateway>
ipconfig /all
ping -n 15 1.1.1.1
net use \\<ipxe_artifact_server_ip>\win-install /user:install /TCPPORT:8445 install
\\<ipxe_artifact_server_ip>\win-install\winserver25_eval\setup.exe
