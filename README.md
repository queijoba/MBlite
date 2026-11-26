# MBLite — My Book · 0.1.1 Alpha

Biblioteca de PDFs hospedados no Google Drive. A coleção inicial Guerra dos Tronos RPG contém seis referências, sem cópia dos arquivos. A configuração privada do catálogo fica na variável de ambiente MBLITE_LINK_CATALOG. Não publicar identificadores de Drive no GitHub público.

## Leitura
O catálogo mostra metadados; o servidor verifica MBLITE_TEST_ACCESS antes de devolver o ID para a visualização incorporada do Drive. O código de teste fica na memória da aba, não em URL ou localStorage. O acesso efetivo depende das permissões do Google Drive. Quem conhece um link compartilhado com qualquer pessoa pode acessá-lo diretamente, independentemente do código do MBLite. Não se trata de DRM. Não altere permissões de compartilhamento sem autorização. Compartilhe apenas obras licenciadas para tal.

O leitor incorporado oferece acesso ao PDF e à interface de download do Drive. Se o iframe não funcionar, abra no Drive. Não há integração de página atual ou exportação de página isolada para os PDFs remotos; essas ferramentas continuam disponíveis para PDFs locais.

## Contas
Modo visitante: favoritos, desejos, últimos vistos, comentários de demonstração, respostas, curtidas e spoilers são locais ao navegador. Não são compartilhados. O ranking local é baseado nos comentários locais.
Modo online (preparado, não conectado): criar um projeto Supabase separado, executar database/setup.sql no projeto novo, verificar as políticas RLS, habilitar autenticação por e-mail/senha com confirmação de e-mail, definir Site URL e redirect URL para o domínio MBLite. Configurar MBLITE_SUPABASE_URL e MBLITE_SUPABASE_PUBLISHABLE_KEY na Vercel. Nunca expor secret/service_role. Não usar o banco PJ Lite. A interface ativa o login real quando essas variáveis estão presentes. Testar duas contas, isolamento de listas, comentários, respostas e curtidas; o ranking inicial agrega até 1000 comentários. O acesso ao PDF ainda depende do código e do Drive. Não há grupos. Os apelidos são escolhidos pelo leitor e não comprovam identidade.
Google OAuth é opcional e não foi conectado nesta versão. O antigo backend de federação foi substituído; revogar a autorização antiga e remover o compartilhamento da conta de serviço no Drive se não forem mais utilizados.

## Administração (proposta)
Catálogo, edição de metadados e capas, organização de coleções, visibilidade, moderar comentários, permissões por usuário e registro de alterações. Senhas por livro só controlam entrega do link dentro do MBLite; manter ACLs do Drive para proteção efetiva. Não usar um botão oculto como autorização de administrador.

## Testes
- Acesso: conferir que a API catalog não inclui driveId e que read sem código retorna 401.
- Navegar, filtrar, abrir visualizador com código; usar fallback do Drive; testar celular.
- Favoritos, desejos, últimos vistos, comentários locais, respostas e spoilers.
- Com banco dedicado, testar contas e políticas RLS antes de convidar leitores.
