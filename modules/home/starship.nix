{ lib, ... }:
{
 programs = {
   starship = {
     enable = true;
     enableZshIntegration = true;
     settings = lib.mkDefault {
       format = lib.concatStrings [
         "$username"
         "$hostname"
         "$directory"
         "$git_branch"
         "$git_state"
         "$git_status" 
         "$nix_shell"
         "$fill"
         "$python"
         "$golang"
         "$status"
         "$line_break"
         "$character"
       ];

       fill.symbol = " ";
       hostname.ssh_symbol = "";
       python.format = "([ $virtualenv]($style)) ";
       rust.symbol = " ";
       status.disabled = false;
       username.format = "[$user]($style)@";

       character = {
         success_symbol = "[❯](purple)";
         error_symbol = "[❯](red)";
         vicmd_symbol = "[❯](green)";
       };

       directory = {
         read_only = " ";
         home_symbol = " ~";
         style = "bold fg:dark_blue";
         truncate_to_repo = false;
         truncation_length = 5;
         truncation_symbol = ".../";
       };

       docker_context.symbol = " ";

       git_branch = {
         symbol = " ";
         format = "[$symbol$branch]($style)";
         style = "fg:green";
       };

       git_status = {
         format = "[(\\($all_status$ahead_behind\\))]($style)";
         style = "bright-black";
         conflicted = "🏳";
         ahead = "⇡\${count}";
         behind = "⇣\${count}";
         diverged = "⇕⇡\${ahead_count}⇣\${behind_count}";
         untracked = "?\${count}";
         stashed = "📦";
         modified = "!\${count}";
         staged = "+\${count}";
         renamed = "»\${count}";
         deleted = "✘\${count}";
       };

       git_state = {
         format = "\([$state( $progress_current/$progress_total)]($style)\) ";
         style = "bright-black";
       };

       golang = {
         symbol = " ";
         format = "[$symbol$version](#88C0D0 bold) ";
       };

       nix_shell = {
         disabled = false;
         symbol = "❄️ ";
         format = "via [$symbol($name)]($style)";
         style = "bold #81A1C1";
       };

       palettes.nord = {
         dark_blue = "#5E81AC";
         blue = "#81A1C1";
         teal = "#88C0D0";
         red = "#BF616A";
         orange = "#D08770";
         green = "#A3BE8C";
         yellow = "#EBCB8B";
         purple = "#B48EAD";
         gray = "#434C5E";
         black = "#2E3440";
         white = "#D8DEE9";
       };
     };
   };
 };
}
