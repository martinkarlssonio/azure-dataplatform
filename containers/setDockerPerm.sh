#Create docker group
sudo groupadd docker
#Add user to docker group
sudo usermod -aG docker ${USER}
#Log out and back in
su -s ${USER}
#Ensure it is possible to run commands without sudo
docker run hello-world