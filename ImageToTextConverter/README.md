# Image To Text Converter

## What does it do?

### This program converts image-based files (such as PDF) into plain text files. It uses Windows Subsystem for Linux and Tesseract, an open-source Optical Character Recognition project.

## How do I use it?

## Setup

#### - See my walkthrough for installing Windows Subsystem for Linux 2 [here](https://github.com/GalacticWafer/WSL_Setup_Walkthrough).

#### - Make sure you have the latest stable version of AutoHotkey installed

#### - Use the following commands to install Tesseract on WSL2:
    ```
	sudo apt update -y && sudo apt upgrade -y
	sudo apt install tesseract-ocr -y
	sudo apt install imagemagick -y 
    ```

#### 4 - The next step authorizes "PDF" files to be changed to high-quality images. Do the same with all the different format types that you plan to extract text from.
    ```
	sudo sed -i_bak 's/rights="none" pattern="PDF"/rights="read | write" pattern="PDF"/' /etc/ImageMagick-6/policy.xml
    ```

#### 5 - Now you can use AHK to run a bash script on Windows Subsystem for Linux which will take care of the actual ocr. AHK is basically just there to kick things off.

#### 6 - Double-click `ImageToTextConverter.ahk` to run the program. From File Explorer, click on the file that you wish to be converted into text, and press `Control` + `Alt` + `Enter`. The time taken to convert the file is proportional to the size of the file. A text file with the same name will be generated from the image-based file.