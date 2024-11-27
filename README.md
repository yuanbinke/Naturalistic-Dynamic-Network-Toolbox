# Naturalistic-Dynamic-Network-Toolbox(NaDyNet)



## **一.** **软件概述**

基于自然刺激的动态脑网络工具箱软件是一款MATLAB的软件，适用于分析自然刺激下的任务态核磁共振数据。旨在推动自然场景神经科学的发展。

自然刺激是指内容丰富且连续的刺激，如电影或真实生活场景。研究这些刺激对脑活动的影响是当前脑科学研究中的一种新兴范式。由于自然刺激内容复杂，fMRI（功能性磁共振成像）信号也相应地变得复杂，包含了多种成分。这也是分析fMRI信号的一个主要难点。

本软件的创新点基于前人的分析fMRI信号的方法上，开创了增强版本的方法，消除无关信号的影响，分离出由自然刺激引发的信号，并实时追踪大脑对这些刺激的反应，并且取得了更加有效的结果，更加适用于自然刺激下的任务态核磁共振数据分析。

本工具箱针对于动态的脑网络方法分析后的结果，通过K均值聚类分析，求出最佳的K, 并且可以聚类出多种状态和相对应的状态转移矩阵，最终在本地保存为图片。

## **一.** **软硬件环境要求**

### **1.** **硬件要求**

该工具箱是分析fMRI（功能性磁共振成像）数据的一款MATLAB软件，由于fMRI数据比较庞大，因此要求内存至少大于等于16G。

对于其他硬件要求，只需要你的电脑可以打开并运行MATLAB 2018a或之后的版本即可

### **2.** **软件要求**

为了能顺利的运行该MATLAB工具箱的相关功能，除了以上的硬件环境以外，还需要一定的软件支持。所需要的软件环境：

1. 操作系统：Windows 7 及以上

2. 网络环境：无要求

3. 运行平台：MATLAB 2018a及其之后的版本

4. MATLAB环境： 要求必须安装以下工具包

   (1) Medical Imaging Toolbox: 这是MATLAB 官方的一款自带的工具包，专门用于图像的处理。(一般是安装MATLAB时自带，在命令行输入如下命令, 如果显示出对应的路径则无需下载该工具包)

   ```matlab
   >> which niftiread
   C:\Program Files\MATLAB\R2022b\toolbox\images\iptformats\niftiread.m
   ```

   

   (2) [SPM](https://www.fil.ion.ucl.ac.uk/spm/software/download/): 在本工具箱中用于读写和操作fMRI文件。

   (3) [Group ICA Of fMRI Toolbox (GIFT)](https://github.com/trendscenter/gift)：用于对数据的结果进行分析。

   (4) [BrainNet Viewer](https://www.nitrc.org/projects/bnv/)： 在本工具箱中用于对3D的NII文件进行可视化，并且保存为图片。如果你无需将3D的NII文件进行可视化和保存的话，这一步是可选的。