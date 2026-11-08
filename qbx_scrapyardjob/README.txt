Root admin access uses FXServer ACE. Example server.cfg lines:
add_ace group.admin scrapyard.root allow
add_principal identifier.license:YOUR_LICENSE_HERE group.admin

Replace the license identifier with a trusted administrator's actual identifier. In game, use /scrapyardadmin. The server verifies permission for every admin callback; the panel can manage business status and auction listings. See README.md for installation/configuration and known limitations.
