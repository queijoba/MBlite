# MBLite — My Book · 0.4v Pre-Alpha

Biblioteca de PDFs hospedados no Google Drive. O catálogo atual reúne Guerra dos Tronos RPG e O Som das Seis RPG, sem cópia dos arquivos originais. A configuração privada do catálogo fica na variável de ambiente MBLITE_LINK_CATALOG. Não publicar identificadores de Drive no GitHub público.

## Leitura
O catálogo mostra metadados; a leitura e as pastas de fichas não exigem código de acesso do MBLite. O acesso efetivo depende das permissões do Google Drive. Quem conhece um link compartilhado com qualquer pessoa pode acessá-lo diretamente pelo Drive. Não se trata de DRM. Não altere permissões de compartilhamento sem autorização. Compartilhe apenas obras licenciadas para tal.

O leitor próprio em PDF oferece sumário, zoom, exportação de página isolada e download quando o carregamento direto funciona. O visualizador integrado do Drive é a alternativa; nele, saltos de página e exportação isolada não estão disponíveis. A interface informa que PDFs podem demorar para carregar. A importação de novos PDFs pessoais foi retirada na versão 0.4v Pre-Alpha; arquivos locais já existentes não são apagados.

## Contas
Modo visitante: favoritos, desejos, últimos vistos, comentários de demonstração, respostas, curtidas e spoilers são locais ao navegador. Não são compartilhados. O ranking local é baseado nos comentários locais.
Modo online (preparado, não conectado): criar um projeto Supabase separado, executar database/setup.sql no projeto novo, verificar as políticas RLS, habilitar autenticação por e-mail/senha com confirmação de e-mail, definir Site URL e redirect URL para o domínio MBLite. Configurar MBLITE_SUPABASE_URL e MBLITE_SUPABASE_PUBLISHABLE_KEY na Vercel. Nunca expor secret/service_role. Não usar o banco PJ Lite. A interface ativa o login real quando essas variáveis estão presentes. Testar duas contas, isolamento de listas, comentários, respostas e curtidas; o ranking inicial agrega até 1000 comentários. O acesso ao PDF depende das permissões do Drive. Não há grupos. Os apelidos são escolhidos pelo leitor e não comprovam identidade.
Google OAuth é opcional e não foi conectado nesta versão. O antigo backend de federação foi substituído; revogar a autorização antiga e remover o compartilhamento da conta de serviço no Drive se não forem mais utilizados.

## Administração (proposta)
Catálogo, edição de metadados e capas, organização de coleções, visibilidade, moderar comentários, permissões por usuário e registro de alterações. Senhas por livro só controlam entrega do link dentro do MBLite; manter ACLs do Drive para proteção efetiva. Não usar um botão oculto como autorização de administrador.

## Testes
- Acesso: conferir que a API catalog não inclui driveId e que read retorna a referência de um livro cadastrado sem código.
- Navegar, filtrar, abrir visualizador sem código; usar fallback do Drive; testar celular.
- Favoritos, desejos, últimos vistos, comentários locais, respostas e spoilers.
- Com banco dedicado, testar contas e políticas RLS antes de convidar leitores.

## Identidade e histórico
Versão atual: 0.4v Pre-Alpha (numeração definida pelo responsável pelo projeto). Siglas: S6 = O Som das Seis RPG; GDT = Guerra dos Tronos RPG (abreviação editorial do MBLite). O rodapé contém o texto Sobre, créditos a Yuva, histórico das versões efetivamente utilizadas e o link de apoio do Telegram.

## Leitura em imagens — preparação para uma etapa futura
O leitor atual permanece em PDF. Não existem páginas PNG publicadas nesta versão. Quando os arquivos autorizados forem fornecidos, converter cada PDF em uma pasta de páginas numeradas na ordem física do arquivo, incluindo capa e contracapa. Preservar o PDF original no Drive. O manifesto por obra deverá conter: bookId (ID estável do catálogo), format (png ou webp), pageCount, pages (lista ordenada de referências de imagem e dimensões), toc (títulos e índices físicos correspondentes), e referência ao PDF original para download. Exemplo de organização: `pages/0001.png`, `pages/0002.png`, `manifest.json`. Antes da publicação, verificar quantidade, ordem, legibilidade e permissões de todos os arquivos. O futuro leitor deverá carregar somente páginas próximas, oferecer modo vertical e página única, preservar o sumário e ter fallback PDF. Nenhuma conversão nem integração do leitor por imagens foi executada ainda.

## Conta e notificações (0.5v Pre-Alpha)
Rotas `/yconta`, `/yconta/favoritos`, `/yconta/desejos`, `/yconta/lendo`, `/yconta/concluidos`, `/yconta/mais-comentados`, `/yconta/notificacoes`, `/obra/:id`, `/colecao?nome=...` e rotas da biblioteca são reescritas para o mesmo HTML na Vercel, preservando a origem da sessão. O OAuth Google continua retornando a `/` (URL já autorizada) e restaura o atalho da conta. A foto do Google é carregada apenas de URL HTTPS do domínio googleusercontent.com, com iniciais como alternativa.
Execute a migração `database/20261127_account_notifications.sql` somente no MBLite Cloud. A central de avisos consulta automaticamente comentários em favoritos e respostas; para cada atualização real de obra publicada, registre no banco via administração autorizada: `insert into public.mblite_book_updates(book_id,description) values ('ID_EXISTENTE','Descrição da atualização efetivamente publicada');`. Não insira eventos fictícios. O usuário vê somente eventos de suas obras favoritas e respostas próprias, até 100 dos últimos 30 dias. Marca de leitura fica na nuvem; consulta ao abrir a conta, ao voltar à janela e a cada minuto com o site visível. Não há envio de e-mail ou push. Estatística de posição acumulada soma posições registradas, não mede leitura efetiva.
