#------------------------Application setup------------------------------

read -p "Do you want to setup any application file for this device (Y/N)? :" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    cd /root/app_codes
    read -p "Enter the Repository to clone :" repo_url
    reponame=$repo_url
    repo=${reponame##*/}
    DIR="/root/app_codes/${repo%%.*}/python_codes"
    if [ -d "$DIR" ]; 
    then
        cd ${DIR}
        pip install -r requirements.txt    
    else
        echo -e "\e[1;41m Folder name 'python_codes' doesn't exist \e[0m"
    fi
    
    DIR="/root/app_codes/${repo%%.*}/web_codes"
    if [ -d "$DIR" ]; 
    then
        cd ${DIR}
        npm install    
    else
        echo -e "\e[1;41m Folder name 'web_codes' doesn't exist \e[0m"
    fi    
    echo -e "\e[1;42m Application has been successfully setup \e[0m"
fi

read -p "Do you want to reboot the device (Y/N)? :" -n 1 -r
echo    
if [[ $REPLY =~ ^[Yy]$ ]]
then
    /sbin/reboot
fi