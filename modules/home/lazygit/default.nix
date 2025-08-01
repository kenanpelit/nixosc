# modules/home/lazygit/default.nix
# ==============================================================================
# LazyGit Enhanced Configuration with Catppuccin Integration
# ==============================================================================
{ inputs, pkgs, ... }:
{
  # =============================================================================
  # Package Installation
  # =============================================================================
  home.packages = (with pkgs; [ lazygit ]);
  
  # =============================================================================
  # Enhanced Configuration (Catppuccin colors handled by module)
  # =============================================================================
  xdg.configFile."lazygit/config.yml".text = ''
    gui:
      border: 'rounded'
      sidePanelWidth: 0.3333
      expandFocusedSidePanel: false
      mainPanelSplitMode: 'flexible'
      language: 'en'
      timeFormat: '02 Jan 06 15:04 MST'
      shortTimeFormat: '15:04'
      
      commitLength:
        show: true
      mouseEvents: true
      skipDiscardChangeWarning: false
      skipStashWarning: false
      showFileTree: true
      showListFooter: true
      showRandomTip: true
      showBranchCommitHash: true
      showBottomLine: true
      showPanelJumps: true
      showCommandLog: true
      nerdFontsVersion: "3"
      showIcons: true

    git:
      paging:
        useConfig: false
        colorArg: always
        pager: delta --dark --paging=never --line-numbers
      
      commit:
        signOff: false
        verbose: false
        autoWrapCommitMessage: true
        autoWrapWidth: 72
      
      merging:
        manualCommit: false
        args: ""
      
      log:
        order: 'topo-order'
        showGraph: 'always'
        showWholeGraph: false
      
      branchLogCmd: 'git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --'
      allBranchesLogCmds:
        - 'git log --graph --all --color=always --abbrev-commit --decorate --date=relative --pretty=medium'
      overrideGpg: false
      disableForcePushing: false
      parseEmoji: true
      diffContextSize: 3
      splitDiff: 'auto'
      skipHookPrefix: WIP
      
      autoFetch: true
      autoRefresh: true
      fetchAll: true
      branchPrefix: ""
      
      pull:
        mode: 'merge'

    update:
      method: prompt
      days: 14
    
    refresher:
      refreshInterval: 10
      fetchInterval: 60

    confirmOnQuit: false
    quitOnTopLevelReturn: false
    disableStartupPopups: false
    notARepository: 'prompt'
    promptToReturnFromSubprocess: true

    customCommands:
      - key: 'C'
        command: 'git commit -m "{{.Form.Type}}{{.Form.Scope}}: {{.Form.Message}}"'
        description: 'Conventional commit'
        context: 'files'
        prompts:
          - type: 'menu'
            title: 'Commit type'
            key: 'Type'
            options:
              - name: 'feat'
                description: 'A new feature'
                value: 'feat'
              - name: 'fix'
                description: 'A bug fix'
                value: 'fix'
              - name: 'docs'
                description: 'Documentation changes'
                value: 'docs'
              - name: 'style'
                description: 'Code style changes'
                value: 'style'
              - name: 'refactor'
                description: 'Code refactoring'
                value: 'refactor'
              - name: 'test'
                description: 'Adding or updating tests'
                value: 'test'
              - name: 'chore'
                description: 'Maintenance tasks'
                value: 'chore'
          - type: 'input'
            title: 'Scope (optional)'
            key: 'Scope'
            initialValue: ""
          - type: 'input'
            title: 'Commit message'
            key: 'Message'
            initialValue: ""
      
      - key: 'P'
        command: 'git push -u origin {{.CheckedOutBranch.Name}}'
        description: 'Push current branch with upstream'
        context: 'localBranches'
      
      - key: 'n'
        command: 'git checkout -b {{.Form.BranchName}}'
        description: 'Create new branch'
        context: 'localBranches'
        prompts:
          - type: 'input'
            title: 'New branch name'
            key: 'BranchName'
            initialValue: ""
      
      - key: 'A'
        command: 'git commit --amend --no-edit'
        description: 'Amend last commit (no edit)'
        context: 'files'
      
      - key: 'o'
        command: 'gh repo view --web || git remote get-url origin | xargs xdg-open'
        description: 'Open repository in browser'
        context: 'global'

    keybinding:
      universal:
        quit: 'q'
        quit-alt1: '<c-c>'
        return: '<esc>'
        quitWithoutChangingDirectory: 'Q'
        togglePanel: '<tab>'
        prevItem: '<up>'
        nextItem: '<down>'
        prevItem-alt: 'k'
        nextItem-alt: 'j'
        prevPage: ','
        nextPage: '.'
        scrollLeft: 'H'
        scrollRight: 'L'
        gotoTop: '<'
        gotoBottom: '>'
        toggleRangeSelect: 'v'
        prevBlock: '<left>'
        nextBlock: '<right>'
        prevBlock-alt: 'h'
        nextBlock-alt: 'l'
        nextMatch: 'n'
        prevMatch: 'N'
        startSearch: '/'
        optionMenu: '?'
        select: '<space>'
        goInto: '<enter>'
        confirm: '<enter>'
        remove: 'd'
        new: 'n'
        edit: 'e'
        openFile: 'o'
        executeShellCommand: ':'
        push: 'P'
        pull: 'p'
        refresh: 'R'
        nextTab: ']'
        prevTab: '['
        undo: 'z'
        redo: '<c-z>'

    os:
      editPreset: 'nvim'
      edit: 'nvim {{filename}}'
      editAtLine: 'nvim +{{line}} {{filename}}'
      open: 'xdg-open {{filename}}'
      openLink: 'xdg-open {{link}}'
  '';
}

