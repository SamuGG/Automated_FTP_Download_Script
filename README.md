##Automated FTP Download For Windows


It's a set of batch files for Windows which download and zip a whole FTP subtree and files without user intervention, aiming the needs for site administrators who can't access an user interface specific application to commit such task.

<u>No GUI needed. No user intervention.</u>

<br/>
**Who May Find This Useful?**

Web site administrators or programmers who need an automatic process to backup some files or a web hosted application, may find this useful.

- **Case Example 1**

> Say you own a hosting for your web and want to perform automatic scheduled backups. You would need to do a Windows scheduled task calling `backup_web.bat` and your site will be downloaded and zipped on your local machine or wherever you specify.

- **Case Example 2**

> Say you have a web application (CMS-like) where you want a backup section, then you simply would have to put a button with some server-side code calling `backup-web.bat`, and your application will store wherever you want a `.zip` file which contains a backup of your FTP folder.

<br/>
###Kown Issues

Right now this solution only works on FTP which subfolders doesn't contain blank spaces in folders names.

If your FTP site contains a directory tree like this:
> FTP root
>> website
>>> subfolder1
>>>> another subfolder <--- problem with this directory name!!!

>>> subfolder2

This solution will not work on such directory tree, because there's a subdirectory with blank space on folder's name.

I'm currently working on a better solution without this drawback.

<br/>
###Usage

Call `backup_web.bat <FTP_IP_Address> <FTP_username> <FTP_password> <FTP_subfolder> <Local_destination_zip_file>`

Example:

    backup_web 192.168.1.100 admin 12345 mywebs/website1 C:\backups\website1.zip


<br/>
###What's Needed

**You need a command line tool to compress files.** In my solution I assume you have 7zip installed, so I just call 7z.exe to compress files.

If you have another command line tool, simply replace the line with yours.

You can download 7zip from [here](http://7-zip.org). You also need to configure your `PATH` environment variable to include where 7zip is installed.
Just execute once

    SET PATH=%PATH%;C:\Program Files\7-zip

