# MBLite — My Book

0.1.0 Alpha — Biblioteca PDF pessoal, com acesso privado à RPG Wiki.

## Acesso
Abra o site, clique em Entrar com Google e escolha uma conta autorizada. Navegue pelas subpastas RPG Wiki e adicione PDFs à estante da sessão. O login identifica o leitor, sem solicitar acesso ao Drive pessoal. O servidor verifica a assinatura do ID token e a lista de leitores autorizados a cada requisição.

## Configuração (administrador)
- Google Cloud: ativar Drive API, STS e IAM Credentials. Conta de serviço dedicada, sem papel de administração no projeto, com permissão de leitor exclusivamente na pasta desejada. Não criar chave JSON.
- Workload Identity Federation: provedor OIDC da equipe Vercel, audiência da equipe, google.subject = assertion.sub. Condição restrita ao subject do projeto de produção. Conceder roles/iam.workloadIdentityUser sobre a conta de serviço apenas ao principal federado correspondente.
- Vercel: habilitar Secure Backend Access / OIDC com emissor Team. Variáveis de ambiente de produção (não publicar valores): MBLITE_GOOGLE_CLIENT_ID, MBLITE_ALLOWED_EMAILS (lista separada por vírgula), MBLITE_DRIVE_ROOT, MBLITE_GCP_PROVIDER (nome completo do provedor com //iam.googleapis.com/), MBLITE_SERVICE_ACCOUNT.
- Google OAuth: cliente Web, origem JavaScript do site, login Google básico. Não solicitar drive.readonly ao leitor. O servidor solicita escopo de leitura usando credencial temporária da conta de serviço.
- Deploy na Vercel, framework Other, raiz, sem comando de build.

## Segurança
Cada consulta de pasta ou arquivo valida a cadeia de pais até a raiz configurada. Atalhos e arquivos não PDF são excluídos; PDFs sem download permitido não podem ser abertos. Não há credenciais de serviço no navegador. A lista de leitores e o identificador da raiz ficam apenas no servidor. As respostas privadas usam no-store. O token do leitor fica na memória da sessão. Não ampliar a lista de leitores sem autorização; compartilhar apenas material autorizado para distribuição.

## Testes
1. Sem login, a API privada deve responder 401; login com conta não autorizada deve responder 403.
2. Login com conta autorizada: abrir raiz, subpasta, adicionar PDF e ler. Testar arquivo pequeno e grande, exportação de página em PNG/PDF, download completo.
3. Testar que um ID de arquivo fora da raiz é rejeitado.
4. Sair e verificar que os materiais compartilhados desaparecem da estante.
5. Testar o leitor no celular.

## Limitações
- Leitor carrega o PDF em blocos de até 2 MiB, com limite total de 150 MiB e montagem na memória; não é streaming de páginas.
- Livros compartilhados, histórico e comentários da biblioteca ficam na sessão; não sincronizam entre dispositivos. PDFs locais continuam em IndexedDB, com metadados locais. Não usar perfil de navegador público.
- Capas de PDFs compartilhados são tipográficas nesta etapa; PDF local pode gerar miniatura.
- Comunidade, moderação, convites, sincronização, upload para servidor e modo offline futuro ainda não implementados.
- Não alterar permissões do Drive pelo aplicativo. A federação precisa ser validada no ambiente real.

Documentação: https://vercel.com/docs/oidc/gcp e https://developers.google.com/identity/gsi/web/guides/verify-google-id-token
