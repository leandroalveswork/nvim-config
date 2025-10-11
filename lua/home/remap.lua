local fsp = require"home.filesystem"

vim.g.mapleader = ' ';

vim.keymap.set('', ',,', function()
  local enter = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
  vim.api.nvim_feedkeys(enter, "", false)
end)

-- voltar ao netrw
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex);

-- em visual mode, mover as linhas selecionadas para baixo (J) ou para cima (K)
vim.keymap.set('v', 'J', ':m \'>+1<CR>gv=gv');
vim.keymap.set('v', 'K', ':m \'<-2<CR>gv=gv');

-- excluir o texto selecionado sem substituir a area de transferencia do nvim
vim.keymap.set('x', '<leader>pp', '"_dP');

-- No linux, requer que "xsel" e "wl-clipboard" estejam instalados
-- yy = copiar na area de transferencia do OS
-- yp = colar com a area de tranferencia do OS
vim.keymap.set('v', '<leader>yy', '"+y');
vim.keymap.set('n', '<leader>yp', '"+p');

-- iniciar uma substituiçao tomando como base o termo que o cursor esta em cima
vim.keymap.set('n', '<leader>s.', ':%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left>');

-- começar uma substuiçao em modo de visualizaçao para
-- apenas substituir os termos dentro da seleção
vim.keymap.set('v', '<leader>s.', ':s//gI<Left><Left><Left>');

-- comandos no terminal
vim.keymap.set('n', '<leader>ttw', '<cmd>!xdg-open http://localhost:4200<CR>', { silent = true });



-- netrw: copiar o caminho
vim.keymap.set("n", "<leader>nyy", function()
  if vim.bo and vim.bo.filetype == "netrw" then
    vim.fn.setreg("+", vim.b.netrw_curdir)
  end
end)

-- netrw: se a area de transferencia for um caminho, copiar os arquivos e diretorios contidos
vim.keymap.set("n", "<leader>nyp", function()
  if vim.bo and vim.bo.filetype == "netrw" then
    local clipb = vim.fn.getreg("+")
    fsp.copy_directory(clipb, vim.b.netrw_curdir)
    fsp.refresh_netrw()
  end
end)

-- netrw: rodar um comando do vim qualquer em todos os arquivos do diretorio
vim.keymap.set("n", "<leader>nya", function()
  if not (vim.bo and vim.bo.filetype == "netrw") then
    return
  end
  local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
  if at_windows then
    print("Vim's argadd is broken in Windows, you can replace in folder with <leader>nyr instead")
    return
  end

  local command = vim.fn.input("Vim command >")


  local path = vim.b.netrw_curdir
  local files = fsp.all_files_recursively(path)

  for _, file in ipairs(files) do
    vim.cmd("argadd " .. file)
  end
  vim.cmd("2,$argdo " .. command .. " | update")

  vim.cmd("2,$argdelete")
  fsp.refresh_netrw()
end)

-- netrw: Replace in folder
vim.keymap.set("n", "<leader>nyr", function()
  if not (vim.bo and vim.bo.filetype == "netrw") then
    return
  end

  local search = vim.fn.input("Search regex >")
  local replace_with = vim.fn.input("Replace with >")


  local path = vim.b.netrw_curdir
  local files = fsp.all_files_recursively(path)

  for _, file in ipairs(files) do
    local lines = fsp.lines_from_file(file)
    for idx, line in ipairs(lines) do
      lines[idx] = string.gsub(line, search, replace_with)
    end
    fsp.write_file_lines(file, lines)
  end
end)


-- Janelas
vim.keymap.set("n", "<leader>wh", function()
  local width = vim.fn.winwidth(0)
  local next = math.floor(width / 2)
  local cw = vim.api.nvim_replace_termcodes("<C-w>", true, false, true)
  vim.api.nvim_feedkeys(next .. cw .. "<", "n", false)
end)
vim.keymap.set("n", "<leader>wj", function()
  local height = vim.fn.winheight(0)
  local next = math.floor(height / 2)
  local cw = vim.api.nvim_replace_termcodes("<C-w>", true, false, true)
  vim.api.nvim_feedkeys(next .. cw .. "-", "n", false)
end)
vim.keymap.set("n", "<leader>wk", function()
  local height = vim.fn.winheight(0)
  local next = math.floor(height / 2)
  local cw = vim.api.nvim_replace_termcodes("<C-w>", true, false, true)
  vim.api.nvim_feedkeys(next .. cw .. "+", "n", false)
end)
vim.keymap.set("n", "<leader>wl", function()
  local width = vim.fn.winwidth(0)
  local next = math.floor(width / 2)
  local cw = vim.api.nvim_replace_termcodes("<C-w>", true, false, true)
  vim.api.nvim_feedkeys(next .. cw .. ">", "n", false)
end)


-- Importar codigo privado
vim.keymap.set("n", "<leader>cm", function()
  local module_name = vim.fn.input("Module >")
  if module_name == "" then
    error("Module \"\" not found")
    return
  end

  local config_path = vim.fn.stdpath("config")
  local external_path = config_path .. "/../nvim-external/" .. module_name
  local result_module_path = config_path .. "/lua/home/" .. module_name
  if not fsp.directory_exists(result_module_path) then
    fsp.create_dir_if_not_exists(result_module_path)
  end
  fsp.copy_directory(external_path, result_module_path)

  local init_path = config_path .. "/lua/home/init.lua"
  local init_lines = fsp.lines_from_file(init_path)
  init_lines[#init_lines + 1] = "require\"home." .. module_name .. "\""
  fsp.write_file_lines(init_path, init_lines)

  fsp.refresh_netrw()
end)
