#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo -e "\nPOR FAVOR RODE ESTE SCRIPT LOGADO NO USUÁRIO ROOT!"
  exit
fi

echo -e "\nCONFIGURANDO FONTES DO GERENCIADOR DE PACOTES..."
rm /etc/apt/sources.list
cat > /etc/apt/sources.list << EOF
deb http://security.debian.org  buster/updates  main contrib non-free
deb http://ftp.br.debian.org/debian buster  main contrib non-free
deb http://ftp.br.debian.org/debian buster-updates  main contrib non-free
deb http://ftp.br.debian.org/debian buster-backports    main contrib non-free
EOF
echo -e "\nFEITO.\n"

echo -e "\nINSTALANDO PACOTES..."
apt-get update
apt-get install samba winbind krb5-user krb5-user -y
echo -e "\nFEITO.\n"

echo -e "\nALTERANDO ARQUIVOS DE CONFIGURAÇÃO..."

#CONFIGURAÇÃO DE INTERFACES DE REDE
rm /etc/network/interfaces
cat > /etc/network/interfaces << EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto ens19
iface ens19 inet static
    address 192.168.33.10
    netmask 255.255.255.0
    gateway 192.168.33.1
EOF

#CONFIGURAÇÃO DOS HOSTS
rm /etc/hosts
cat > /etc/hosts << EOF
127.0.0.1   localhost
192.168.33.10   dc1.samdom.minhaempresa.com dc1

::1 localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

systemctl restart networking

#CONFIGURAÇÃO DO SAMBA/KRB5
echo -e "\nDESABILITANDO SERVIÇOS..."
systemctl stop smbd nmbd winbind
systemctl disable smbd nmbd winbind

echo -e "\nAPAGANDO CONFIGURAÇÕES DO SAMBA..."
rm /etc/samba/smb.conf
rm /etc/krb5.conf

echo -e "\nEXECUTANDO SAMBA PDC."
echo -e "\nATENÇÃO!!! A OPÇÃO DNS FORWARDER IP ADDRESS DEVE SER 192.168.33.1."
samba-tool domain provision --use-rfc2307 --interactive

cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
systemctl unmask samba-ad-dc.service
systemctl start samba-ad-dc.service


#RESOLV.CONF
rm /etc/resolv.conf
cat > /etc/resolv.conf << EOF
domain samdom.minhaempresa.com
search samdom.minhaempresa.com
nameserver 192.168.33.10
EOF

cat > /root/Aut2.sh << EOF
#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo -e "\nPOR FAVOR RODE ESTE SCRIPT LOGADO NO USUÁRIO ROOT!"
  exit
fi

kinit administrator
echo -e "Digite as senhas conforme descrito na prova."
samba-tool group add GRALUNOS
samba-tool group add GRPROFESSORES
samba-tool group add GRCOORDENADORES
samba-tool user create Pedro
samba-tool user create Paulo
samba-tool user create Priscila
samba-tool user create Jorge
samba-tool user create João
samba-tool user create Celso
samba-tool group addmembers GRALUNOS Pedro
samba-tool group addmembers GRALUNOS Paulo
samba-tool group addmembers GRALUNOS Priscila
samba-tool group addmembers GRPROFESSORES Jorge
samba-tool group addmembers GRPROFESSORES João
samba-tool group addmembers GRCOORDENADORES Celso

echo -e "\nPROVA FINALIZADA."
EOF

chmod +x /root/Aut2.sh

echo -e "\nAGORA RETORNE PARA O SERVIDOR DE CONEXÃO E EXECUTE A PARTE 2 DO SCRIPT."