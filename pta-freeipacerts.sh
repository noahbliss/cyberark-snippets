# Install trusted certificates when cyberark pta is part of a freeipa domain. 
hostname $(hostname -f) && hostname -f > /etc/hostname # Make sure we default to long hostnames. 
cat <<'EOF' > /usr/local/sbin/ipa-ptacertupdate.sh
#!/usr/bin/env bash
CERT_FILE=/etc/pki/tls/certs/$(hostname -f).pem
KEY_FILE=/etc/pki/tls/private/$(hostname -f).key
keyfilepass=$(grep -o 'keystorePass=[a-z0-9"]*' /opt/tomcat/conf/server.xml | sed 's/keystorePass="//g' | sed 's/"//')

cat $CERT_FILE /etc/ipa/ca.crt > /opt/tomcat/ca/ca-cyberark.cert
openssl pkcs12 -export -in $CERT_FILE -inkey $KEY_FILE -chain -CAfile /etc/ipa/ca.crt -name "$(hostname -f)" -out /etc/pki/tls/$(hostname -f).p12 -password pass:$keyfilepass
/usr/java/jdk1.8.0_252/bin/keytool -importkeystore -deststorepass $keyfilepass -destkeystore /opt/tomcat/ca/keystore-cyberark.jks -srckeystore /etc/pki/tls/$(hostname -f).p12 -srcstoretype PKCS12 -srcstorepass $keyfilepass
mv /opt/tomcat/ca/keystore-cyberark.jks /opt/tomcat/ca/keystore-cyberark.key
chmod 744 /opt/tomcat/ca/keystore-cyberark.key
systemctl restart tomcat
EOF
chmod +x /usr/local/sbin/ipa-ptacertupdate.sh
CERT_FILE=/etc/pki/tls/certs/$(hostname --fqdn).pem; KEY_FILE=/etc/pki/tls/private/$(hostname --fqdn).key
mkdir -p /etc/pki/tls/{certs,private}
ipa-getcert request -f ${CERT_FILE} -k ${KEY_FILE} -C "/usr/local/sbin/ipa-ptacertupdate.sh"
