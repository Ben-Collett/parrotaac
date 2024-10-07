# LibreAAC

LibreAAC is a program written in flutter. It is currently in development and has not been released yet.
## What is an AAC?
AAC (Augmentative and alternative communication) devices are used by nonverbal individuals to communicate. The most common AAC device that we've seen (besides TTS technically) is a device that lets a user press buttons to say words which correspond with text and pictures shown on the button. This is the kind of AAC we intend the app to be.

## Mission
The ultimate goal of LibreAAC is to serve as an open source alternative to current AACs on the market. It aims to be both free as in cost and free as in freedom. LibreAAC aims to allow users full control of their AAC. No data of users will be collected. There are no plans to allow any central servers for people to connect to. If such servers ever did come to exist, then designing it so that users can self-host would be the top priority. The reason for this is that many AAC apps connect to a central server, and because of that, the owners' of said servers can flip the switch on users speech at any time. No one should be able to take away a persons sole means of speech, as free speech is a fundamental human right. LibreAAC will be cross-platform for both IOS and Android, and while not being designed for computer, it will be written such that it can function on PCs (just don't expect as smooth of an experience on PC as on mobile). 
## Installation
First, ensure that you have git and flutter installed, then execute the command:
```
git clone https://github.com/Ben-Collett/LibreAAC
```
then get the dependencies: 
```
flutter pub get
```
if you just want to run the program on a connected device then use:
```
flutter run --release
```
if you want to build the code then install it to a connected device then run:
```
flutter build <platform> --release
```
The command you put in for \<platform\> will depend on your target platform, to know the instruction consult the official flutter documentation.


Then after building, to install LibreAAC on your device, use:
```
flutter install
```

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details
