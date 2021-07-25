# Time Machine

`Time Machine` is a complete and fully automated incremental disk backup solution for `MacOS`. It uses [rsync](https://rsync.samba.org/download.html) to perform incremental backups. `launchd` services take care of scheduling and take note of disk (un)mounts. Optionally, install [Growl](https://github.com/growl/growl/tags) and [growlnotify](https://github.com/growl/growl/tags) to receive notifications.

`Time Machine` is specifically targeted at users of Apple's `Photos.app` who have their library on one (external) drive and backup to another (external) drive. Like to Apple's native Time Machine solution, `hard links` are created for unchanged files. Furthermore, backups are organized in a comparable folder structure and backups are automatically consolidates on a weekly, monthly, and yearly basis.

## Usage

Move the folder containing `Time Machine` to `Library/Application Support` in your home directory. Next, check and update the configuration in `etc/config`. The three most important parameters and their meaning are listed in the table below.

|parameter|meaning|
--------|-----
|`SOURCE_FOLDER`|folder to backup|
|`TARGET_VOLUME`|target volume|
|`TARGET_FOLDER`|target folder|

Copy `net.ddns.christiaanboersma.timemachine.plist` from the `share` folder to `Library/LaunchAgents` in your home directory. Log out and back in.

## Notes

1. `Time Machine` relies on `unbuffer`, which can be installed via [Homebrew](https://brew.sh).
2. Logging is done to `Library/Logs/TimeMachine.log` in your home directory.

## BSD-3 License

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
