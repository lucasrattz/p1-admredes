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
apt-get install bind9 isc-dhcp-server squid apache2 -y
echo -e "\nFEITO.\n"

echo -e "\nALTERANDO ARQUIVOS DE CONFIGURAÇÃO..."

#CONFIGURAÇÃO DE INTERFACES DE REDE
rm /etc/network/interfaces
cat > /etc/network/interfaces << EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto ens18
allow-hotplug ens18
iface ens18 inet dhcp

auto ens19
iface ens19 inet static
    address 192.168.33.1
    netmask 255.255.255.0
EOF

#CONFIGURAÇÃO DO BIND9 DNS
rm /etc/bind/named.conf.options
cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";

    forwarders {
        199.85.126.20;
        208.67.222.123;
        208.67.220.123;
    };

    dnssec-validation auto;
};

acl internals {
    127.0.0.0/8;
    ::1/128;
    192.168.33.0/24;
};
EOF

#CONFIGURAÇÃO DE DHCP
echo -e "\nDigite o endereço MAC do PCPr1 (pode ser encontrado na última opção da aba de Hardware da VM.\n"
read PCPR1

echo -e "\nDigite o endereço MAC do PCLa1.\n"
read PCLA1

echo -e "\nDigite o endereço MAC do PCBi1.\n"
read PCBI1

rm /etc/default/isc-dhcp-server
cat > /etc/default/isc-dhcp-server << EOF
INTERFACESv4="ens19"
EOF

rm /etc/dhcp/dhcpd.conf
cat > /etc/dhcp/dhcpd.conf << EOF
authoritative;
option wpad-url code 252 = text;
option wpad-url "http://192.168.33.1/wpad.dat\n";

ddns-update-style none;

option domain-name "home.lan";
option domain-name-servers 192.168.33.1;

default-lease-time 600;
max-lease-time 7200;

subnet 192.168.33.0 netmask 255.255.255.0 {
    range 192.168.33.50 192.168.33.222;
    option routers 192.168.33.1;
    option broadcast-address 192.168.33.255;
}

host PCPr1 {
    hardware ethernet $PCPR1;
    fixed-address 192.168.33.100;
}

host PCLa1 {
    hardware ethernet $PCLA1;
    fixed-address 192.168.33.200;
}

host PCBi1 {
    hardware ethernet $PCBI1;
    fixed-address 192.168.33.50;
}
EOF

#CONFIGURAÇÃO DO SQUID PROXY
cat > /etc/squid/squid.conf << EOF
http_port 3128
visible_hostname servidorInternet

acl redelocal src 192.168.33.0/24

http_access allow redelocal
EOF

#ATIVANDO PROXY AUTOMÁTICO
cat > /var/www/html/wpad.dat << EOF
function FindProxyForURL(url, host) {
    return "PROXY 192.168.33.1:3128";
}
EOF

echo -e "\nFEITO..."

#APLICANDO CONFIGURAÇÕES
echo -e "\nAPLICANDO CONFIGURAÇÕES..."
systemctl restart networking
systemctl restart bind9
systemctl restart isc-dhcp-server
systemctl restart squid

cat > /root/Cnx2.sh << EOF
#!/bin/bash
sed -i "s/home.lan/samdom.minhaempresa.com/" /etc/dhcp/dhcpd.conf
sed -i "s/192.168.33.1;/192.168.33.10\noption netbios-name-servers 192.168.33.10;/" /etc/dhcp/dhcpd.conf

echo -e "SERVIDOR DE CONEXÃO 100% CONFIGURADO. EXECUTE A ÚLTIMA PARTE DO SCRIPT NO SERVIDOR DE AUTENTICAÇÃO."
EOF

chmod +x /root/Cnx2.sh

echo -e "\nCONFIGURAÇÕES APLICADAS..."
echo -e "\nAGORA PROSSIGA PARA O SERVIDOR DE AUTENTICAÇÃO ANTES DE EXECUTAR A PARTE 2 DO SCRIPT."