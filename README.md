# MBLite — My Book
**0.1.0 Alpha · Sua estante, em qualquer lugar.**

Protótipo estático responsivo de biblioteca PDF. O código não contém PDFs do Google Drive, IDs de documentos privados ou credenciais.

## Teste
- Abra a pasta do repositório com um servidor HTTP local: `python -m http.server 8000`. Acesse http://localhost:8000.
- Use o caderno de demonstração original de cinco páginas criado pelo próprio aplicativo.
- Adicione um PDF local, filtre pela categoria, marque favorito, abra o leitor, avance, salve um marcador, exporte o PDF completo, a página como PDF e a página como PNG.
- Volte e reabra para conferir a página salva. Experimente o modo vertical (blocos de cinco páginas), mangá RTL e tema claro. Comentários e spoilers são locais.
- Teste no Chrome/Edge e no celular. Não use file://. O leitor usa PDF.js 4.10.38 e pdf-lib 1.17.1 via CDN; exige conexão para carregar essas bibliotecas.

## Hospedagem
1. Acesse https://vercel.com/new, conecte o GitHub e importe queijoba/MBlite.
2. Framework Preset: Other. Root Directory: raiz. Sem build e sem instalação; output directory: "." (raiz).
3. Deploy. Anote a origem HTTPS exata do domínio.

## Google Drive
1. https://console.cloud.google.com/ — crie um projeto MBLite separado.
2. APIs & Services > Library > Google Drive API > Enable.
3. Google Auth Platform > Branding: configure o nome e contatos. Audience: External (contas pessoais); mantenha em Testing, adicione seu e-mail e os e-mails dos testadores.
4. Clients > Create Client > Web application. Em Authorized JavaScript origins, adicione a origem HTTPS da Vercel e http://localhost:8000 para testes locais. Não inclua caminhos.
5. Data Access: configure o escopo https://www.googleapis.com/auth/drive.readonly e os escopos básicos openid, email, profile. É um escopo restrito; o uso externo em produção pode exigir verificação do Google.
6. Copie somente o Client ID público para o campo Google / Configurar no MBLite. Não cole o Client Secret. O fluxo de token em popup não exige redirect URI no app.
7. Conectar Google > Selecionar PDFs do Drive. Ou Adicionar PDF > cole o link de um arquivo acessível. Os documentos não ficam no GitHub; o token não é persistido. Reautorize em outra sessão ou ao expirar.
8. Cada leitor precisa de permissão própria no Drive. O MBLite não altera permissões, não contorna restrições de download e não é um servidor de distribuição.

Documentação: https://developers.google.com/identity/oauth2/web/guides/use-token-model e https://developers.google.com/workspace/drive/api/guides/manage-downloads.

## Limitações / próxima etapa
- Progresso, estante, favoritos e comentários ficam no navegador, não sincronizam.
- Arquivos locais em IndexedDB; limpeza de dados do site os remove. Metadados em localStorage, visíveis a quem usar o mesmo perfil do navegador. Não use dispositivo público.
- PDFs do Drive são carregados integralmente em memória ao abrir; arquivos muito grandes podem pesar em celular. Capas são tipográficas nesta alpha, não imagens da primeira página. Um marcador por livro.
- Conta Google nesta versão é autorização do Drive, não autenticação de comunidade. Para fase 2: Supabase separado com Auth Google, tabelas de membros, livros, progresso, comentários, favoritos; RLS em todas, isolamento por usuário e grupos autorizados; bucket privado para obras autorizadas, URLs temporárias e políticas de Storage. Não exponha service role, secret key, OAuth secret ou tokens.
- Comentários comunitários, convites, sincronização, capas reais e hospedagem de arquivos no servidor ainda não implementados.
- Compartilhe apenas materiais próprios, domínio público ou licenciados para distribuição.

## Roteiro
0.2: autenticação Google com Supabase e sincronização. 0.3: comunidade, moderação e permissões. 0.4: capas, volumes e capítulos, leitura contínua aprimorada, otimização para PDFs grandes.
