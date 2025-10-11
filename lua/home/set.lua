local EditStyleEnum = { Personal = 1, Job = 2 }

vim.g.edit_style = EditStyleEnum.Personal


-- cursor em bloco ao inves do cursor fino enquanto digita
vim.opt.guicursor = 'a:block';

-- não transformar os caminhos de diretorio colocando '\' no final
-- isso é necessário para o netcoredbg funcionar corretamente no Windows
local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
if at_windows then
  vim.defer_fn(function()
    vim.opt.shellslash = false
  end, 2000)
end

-- mostrar numero das linhas ao lado
vim.opt.number = true;
-- mostrar linhas relativas a linha que o cursor está
vim.opt.relativenumber = true;

-- tab
if vim.g.edit_style == EditStyleEnum.Personal then
  vim.opt.tabstop = 2;
  vim.opt.softtabstop = 2;
  vim.opt.shiftwidth = 2;
else
  vim.opt.tabstop = 3;
  vim.opt.softtabstop = 3;
  vim.opt.shiftwidth = 3;
end
vim.opt.expandtab = true;

-- scroll horizontal quando houver uma linha muito grande
vim.opt.wrap = false;

-- não manter backup dos arquivos, mas configurar a pasta de dados do undodir
vim.opt.swapfile = false;
vim.opt.backup = false;

local at_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1
if at_windows then
  vim.opt.undodir = os.getenv('appdata') .. '/vim/undodir';
else
  vim.opt.undodir = os.getenv('HOME') .. '/.vim/undodir';
end
vim.opt.undofile = true;

-- ativar cores
vim.opt.termguicolors = true;

-- pelo menos apresentar 8 linhas abaixo e acima, para o cursor não ficar muito acima ou muito abaixo
vim.opt.scrolloff = 8;
-- colorir uma coluna hipotética para padronizar a sugestão de até em que momento quebrar na próxima linha
vim.opt.colorcolumn = '120';

