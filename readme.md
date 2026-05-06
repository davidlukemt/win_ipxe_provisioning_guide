## Usage
This is a basic guide for creating a iPXE install artifact server for Windows using wimboot from the iPXE team, an http server, a SMB server, and an extracted Windows Install ISO. This process has only been tested with Windows Server 2025, other versions may require driver injection which is not covered in this guide. Learn more about adding drivers to windows offline images here: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-and-remove-drivers-to-an-offline-windows-image?view=windows-11

### Sources
https://ipxe.org/wimboot

https://github.com/ipxe/wimboot/

https://rpi4cluster.com/pxe-windows-10/

## Guide

### Acquire Windows Server OS Install ISO
	Evaluation Center Server 2025: https://www.microsoft.com/en-us/evalcenter/evaluate-windows-server-2025

### Create Install Artifact server (LSH VM or small instance recommended)

### Install dependencies/tools
```
sudo apt install -y podman
```

### Copy WinServer ISO to VM environment
(ie scp/rsync/etc from terminal, winscp for Windows GUI, etc)
```
scp -i <path_to_ssh_key> winserver25_eval.iso ubuntu@<artifact_server_ip>:~/
```

### Create file structure for http and smb server containers
```
sudo mkdir -p /opt/pxe/wimboot /opt/pxe/winserver25_eval
```

### Extract ISO to target directory to be shared with http and samba (.../winserver/x64/<ISO_Contents>)
```	
# Mount ISO
sudo mount ~/winserver25_eval.iso /mnt
# Copy contents to x64/ directory
sudo cp -R /mnt/* /opt/pxe/winserver25_eval/
```

### Download wimboot from iPXE github repository into the wimboot directory
```
curl --output-dir /opt/pxe/wimboot/ -O https://github.com/ipxe/wimboot/raw/refs/heads/master/wimboot
```

### Download the winpeslh.ini and isntall.bat examples from this repository into the /opt/pxe/wimboot directory
```
curl --output-dir /opt/pxe/wimboot/ -O https://github.com/
curl --output-dir /opt/pxe/wimboot/ -O https://github.com/
```

### Start http-server container
```
podman run -d --rm --name http-server -p 5000:5000 -v /opt/pxe:/html:ro,z ghcr.io/patrickdappollonio/docker-http-server:v2
sudo ufw route allow in on enp1s0 out on podman0 to any port 5000 
```

### Start samba server container
```	
podman run -d --rm --name samba -p 8445:445 -e "NAME=win-install" -e "USER=install" -e "PASS=install" -v /opt/pxe:/storage docker.io/dockurr/samba
sudo ufw route allow in on enp1s0 out on podman0 to any port 8445 
```

### Deploy Bare Metal server with following Custom iPXE script
```
#!ipxe
echo Note server public IP address in LSH Dashboard and 
echo enter it into the netsh line of the install.bat 
echo file downloaded earlier, then...
prompt Press any key to continue
dhcp

# Enter IP of artifact server before deployment
set boot-url http://<public_ip_of_artifact_server>:5000

kernel ${boot-url}/wimboot/wimboot gui
initrd ${boot-url}/wimboot/winpeshl.ini     winpeshl.ini
initrd ${boot-url}/wimboot/install.bat      install.bat
initrd ${boot-url}/winserver25_eval/boot/bcd         BCD
initrd ${boot-url}/winserver25_eval/boot/boot.sdi    boot.sdi
initrd ${boot-url}/winserver25_eval/sources/boot.wim boot.wim

boot || goto failed
```

### Once available, open Remote Access to newly deployed Bare Metal server and launch the Remote Control Console

### The above iPXE script has a pause prompting for input to continue to hold the deployment process until you have Console access. 
	
>[!IMPORTANT]	
>Use this pause to note the Public IP of the Bare Metal server on the LSH server page
Enter this IP and the related default gateway into the install.bat file in the netsh line

>[!NOTE]	
>Note the interface name in the netsh line of the install.bat file may need to be modified based on which interface is the public interface of the deployed bare metal server

Once install.bat file is updated with the public IP of the server, press any key on the bare metal server console to continue the iPXE boot process

After loading the wimboot environment, the install.bat script will:
+ initialize wimboot networking
+ print network configuration with ```ipconfig /all``` command
+ ping 127.0.0.1 5 times to wait for network initialization to complete
+ set the IP address on the Public interface of the bare metal server with ```netsh interface``` command
+ print network configuration again for Public IP config validation
+ ping 1.1.1.1 to both test Public IP config and wait for networking to start functioning as expected
+ mount the SMB share with extracted install ISO files
+ run the setup.exe Windows OS install application

>[!NOTE]	
>If Network Interfaces don't show up as expected, you will need to modify the windows install to include relevant drivers for the Network Interfaces on the Bare Metal server
>https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-and-remove-drivers-to-an-offline-windows-image?view=windows-11

### Click through Windows OS install application as normal

>[!NOTE]	
>If drives don't show up as expected, you will need to modify the windows install to include relevant drivers for storage on the Bare Metal server
>https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/add-and-remove-drivers-to-an-offline-windows-image?view=windows-11
