# TODO — App Prestador: botão Waze/Google Maps na tela 3D

**Repo:** `C:\Projetos\kz-servicos-app-prestador` (NÃO é este repo)
**Origem:** brainstorm 2026-05-21

## Pedido
Na tela 3D tilt (`navigatingToClient` / `tripInProgress` — ver spec
`docs/superpowers/specs/2026-05-20-in-trip-flow-design.md` §3.5/§3.7), adicionar
um botão flutuante redondo no canto direito que abra a rota num app externo
(Waze ou Google Maps).

## Pontos a decidir quando for implementar
- Bottom sheet com escolha (Waze / Google Maps) ou abrir direto no app preferido?
- Para qual destino abrir? Pickup do cliente em `navigatingToClient`, destino
  final em `tripInProgress`.
- Esquemas de URL:
  - Waze: `waze://?ll=<lat>,<lng>&navigate=yes`
  - Google Maps: `google.navigation:q=<lat>,<lng>` (Android) /
    `comgooglemaps://?daddr=<lat>,<lng>&directionsmode=driving` (iOS)
  - Fallback web: `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>`
- Pacote sugerido: `url_launcher` (já comum em apps Flutter).

## Onde encaixar
- Widget da tela 3D do prestador. Posicionar em `Positioned(right: 16, bottom: ~120)`
  acima do painel inferior. `FloatingActionButton` redondo, ícone de navegação.
