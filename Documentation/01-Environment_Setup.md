# Environment Set-Up

The first thing to do in this research is to set-up the environment. For start, we need to initiate WSL.

## Windows Subsystem for Linux (WSL)

The default setting for any Windows system is disabled. We need to enable the feature through the setting. Search `windows features` on the search bar and open the control panel setting showed up. On the control panel, scrol down until you find `Windows Subsystem for Linux` and checked the box. Click Ok and the system will ask you to restart the system.

![Searching Windows Features setting on Windows search bar](../Images/001-Windows_Features.png)

![Enabling WSL in the Windows Features setting](../Images/002-Turn_on_WSL.png)

After enabling WSL, we need to restart the system. Do not forget the save all working progress before restarting. Then we need to open Terminal and type `wsl --update` to update the current wsl version. Wait until it finishes. The next step is to install Linux distribution or distro. There are many options to choose, but in this documentation we will install Ubuntu. We can install Ubuntu through Terminal by typing `wsl --install Ubuntu` or just searched up on the Microsoft Store to install the distro.

![Updating and Installing Linux distro on the Terminal](../Images/003-First-setup-WSL.png)

To start up Ubuntu, we can either type `ubuntu` on the Terminal or click it on the start menu. It then will ask us to set up the username and password. The password will be required if we use `sudo` on the Ubuntu. For start, we will update and upgrade the repository by typing this code on the Terminal:

```shell
# this line is to update the repository
sudo apt update 

# this line is to upgrade all the upgradable packages
sudo apt upgrade 
```

After that, we will install several packages that we need in this research: NetCDF, NCView, CDO, NCO, Anaconda (python), and Java. To install the packages, type this code:

```shell
# installing packages through aptitude
sudo apt install netcdf-dev ncview cdo nco default-jre

# these lines is to download and install Anaconda
curl -O https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh
bash ~/Anaconda3-2024.10-1-Linux-x86_64.sh
```

Feel free to explore through the Ubuntu to familiarize with the system!

## Visual Studio Code

This step is not necessary for this research, but Visual Studio Code (VS Code) is a powerful tool. We can integrate WSL directory on VS Code, so that we could modify and run our code seamlessly. To install it, just search `VS Code` on Microsoft Store. After that we need to initiate it by typing `code .` on Ubuntu terminal.

![Searching Visual Studio Code on Microsoft Store](../Images/004-Installing_VS_Code.png)

Just play around the VS Code to familiarize yourself with the workflow and look up any documentation on the internet!

## MatLab

MatLab is a powerful versatile tool for data analysis and visualization, although it is not free nor open-source. If your university provides a license, you can ask them on how to acquire it. In this research, our university ITS provides a education license for MatLab. One should register for an account on the [MatLab website](https://www.mathworks.com/), and do not forget to use your university email (the one that has the domain of your uni, for ITS students/lecturers it is (at)its.ac.id). After activating the account, you can download the installer on the [website](https://matlab.mathworks.com/). Fortunately, Mathworks provides support for every operating system: Windows, MacOS (Intel and Apple Silicon), and Linux.

![Downloading MatLab installer on the Mathworks website](../Images/005-Downloading_MatLab.png)

The latest version as of June 2025 was R2025a, which has support for Copilot AI that we can use to ask help for our code. To install the software, please follow the instructions on the website accordingly. The installer will ask you to log in to your account. 

![MatLab installer opening page](../Images/006-Installer_MatLab.png)

When it ask what to install, you should at least select MatLab and Mapping Toolbox. After the installation is complete, you can open MatLab and start coding! Just search up any example on the internet and familiarize yourself with the system!

![Choosing what to install... part 1](../Images/007-Choose_MatLab.png)

![Choosing what to install... part 2](../Images/008-Choose_Mapping.png)

![MatLab opening page](../Images/009-MatLab_Opening_Page.png)