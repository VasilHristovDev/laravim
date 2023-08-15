# Laravim
Laravim is a vim configuration for Laravel development.

## Installation
You have to clone it under the `~/.vim/proc/start/<user-name>` directory.
Where `<user-name>` is your user.

```bash
git clone https://github.com/VasilHristovDev/laravim.git ~/.vim/proc/start/<user-name>    
```

## Usage
When you open a Laravel project, Laravim will automatically load the configuration.

## Features
- When inside api.php or web.php, you can press `gh` to open the Controller/View under the cursor.
- When inside a .php file you can press `gc` to open the Class file under the cursor.
- When inside a .php file you can press `gd` to open the Class file with the method under the cursor.
- You can run Composer commands from inside vim. `:ExecuteComposerCommand <command>`
- You can run Artisan commands from inside vim. `:ExecuteArtisanCommand <command>`
- You can check whether the currently opened project has composer installed. `:HasComposer`
- You can check whether the currently opened project is a Laravel project. `:IsLaravel`
- You can list all artisan commands available. `:ListArtisanCommands`

