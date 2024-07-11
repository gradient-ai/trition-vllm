
echo "Remove existing nvidia drivers"
sudo apt autoremove cuda* nvidia* --purge -y
echo "adding nvidia repo"
sudo add-apt-repository ppa:graphics-drivers/ppa -y
echo "adding nvidia container toolkit"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update -y
echo "install nvidia 555 driver"
sudo apt install nvidia-driver-555 -y
echo "install nvidia cuda toolkit"
sudo apt install nvidia-cuda-toolkit -y
echo "install nvidia container toolkit"
sudo apt-get install -y nvidia-container-toolkit
echo "install docker"
sudo apt install docker.io -y

sudo reboot