## Welcome to PixelOC!
### <font color="red"> Please note that there will be program-breaking changes, so please carefully read the changelog before updating! </font>
### What is this?
PixelOC is a graphics library for OpenComputers.
The library is specifically made and tested on GregTech: New Horizons' version of OpenComputers, but might work for other versions as well, I don't know.
I made this library with some inspiration from the JavaFX architecture, so it uses classes and Panes

### How do I use this library?
Currently there is no releases yet, since I've only just started work on the library and there will be many program-breaking changes. Want to check it out anyways? Download the repository as a zip and put the UI folder in your OpenComputers computer instead of the zip mentioned below.
1. Go to the [releases](https://github.com/guid118/PixelOC/releases) page and download the latest release.
2. Unzip the downloaded zip file and put it into the home directory of your OpenComputers computer (if you don't know where to find this, read [this](#where-is-my-home-folder))
3. Make a program that uses the library! You can find an example in the [tests](https://github.com/guid118/PixelOC/tree/master/UI/tests) folder.


### What is to come?
My current to do list is very long, but notable features include:
- Shifting to a system where panes are necessary to show anything, thus eliminating the need for elements to know where they are located.
- TabPane and ScrollPane additions
- Color utils, so you can easily use colors from the default colors, and edit the 16 palette colors.
- Debug utils, so print statements don't break the UI
- MANY bug fixes, the library is probably full of bugs that I have not yet found. (Did you find a bug? please [report](#i-found-a-bug-what-now) it!)
- More, probably...


### I found a bug! What now?
Please check on the [issues](https://github.com/guid118/PixelOC/issues?q=is%3Aissue%20state%3Aopen)
page if someone else has also reported this bug. If not, please make a bug report explaining what this bug is, and how you managed to cause it (How can I repeat it?)

If you're an experienced OpenComputers programmer yourself, you can try fixing it yourself and creating a pull request (If you don't know how, you can also provide the code in the bugreport, but pull requests are easier for me to implement!)


### Where is my home folder?
1. Install the computer you want to run the library on
2. Find the address of the hard drive of the computer you just installed
3. Locate your world folder (usually found in `%appdata%/.minecraft/saves/<worldname>` on windows in singleplayer). Unfortunately I have no idea how you can get the whole library in a computer on a server that you do not have file access to.
4. In your world folder, locate the `opencomputers` folder, and in that locate the folder with the address of your hard drive.
5. Congratulations, you will now see a bunch of folders, one of which should be `home`