SET NAME=save_state_v0
mv %NAME%.ips %NAME%_old.ips
touch %NAME%.ips
..\bin\xkas.exe main.asm %NAME%.ips
