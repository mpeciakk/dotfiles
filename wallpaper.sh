for monitor in $(hyprctl monitors | grep 'Monitor' | awk '{ print $2 }'); do
  hyprctl hyprpaper preload "$HOME/dotfiles/wp.png"
  hyprctl hyprpaper wallpaper "$monitor,$HOME/dotfiles/wp.png"
done
