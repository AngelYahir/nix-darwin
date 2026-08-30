{ pkgs, ... }: 
{
    services.jankyborders = {
        enable = true;

        width = 4.0;
        style = "round";

        active_color = "#cba6f7";
        inactive_color = "#9399b2";

        hidpi = true;
    };
}