# windows-applications-updater

windows-applications-updater is a simple to use script that takes care of updating all your Windows applications at once.

## Features

- Support for all semi-recent versions of Windows 10/11.
- Very simple to set up, even if you're not tech-savy.
- Super convenient to use, just fire and forget.

## Installation and Getting Started

1. Download the [App-Installer](https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1)[^app-installer] package from the Microsoft Store.

2. Download the [latest version of this script](https://github.com/Freddythereal/windows-applications-updater/releases/latest/download/windows-applications-updater.bat).

3. Double-left-click on the downloaded **windows-applications-updater.bat** file to run it.

4. A Windows prompt will open with the following message:

   `Do you want to allow this app to make changes to your device?`

   Single-left-click on the Yes button to agree.[^administrator_access]

5. Wait for the script to finish. Afterwards the terminal window will close itself.

[^app-installer]: App-Installer is an official and free Microsoft package that includes winget[^winget].
[^winget]:
    Winget (also known as Windows Package Manager) is the official, free and open-source package manager designed by Microsoft for Windows 10 and Windows 11. This script requires winget to be installed on your system to work. You can learn more about winget [here](https://learn.microsoft.com/windows/package-manager/winget/).

[^administrator_access]: This script must run with Administrator Access because otherwise each indivdual application installer/updater would have to prompt the user for consent before being able to run.

## Additional Information

- Performing a left-click on the terminal window will pause the exectution of the script.
  Press Enter to resume it.

## License

windows-applications-updater is licensed under the [MIT License](https://github.com/Freddythereal/windows-applications-updater/blob/master/LICENSE).
