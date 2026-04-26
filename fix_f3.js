const fs = require('fs');

const tryReplace = (c, o, n, label) => {
  const oCR = o.replace(/\n/g, '\r\n'), nCR = n.replace(/\n/g, '\r\n');
  if (c.includes(oCR)) { console.log(label + ' OK (CRLF)'); return c.replace(oCR, nCR); }
  if (c.includes(o))   { console.log(label + ' OK (LF)');   return c.replace(o, n); }
  console.log('ERROR: ' + label);
  return c;
};

// ─── F3a: Swap bouton ticket → calendrier sur profil ───
const profileFile = 'lib/pages/new_pages/user_profile/user_profile_widget.dart';
let pc = fs.readFileSync(profileFile, 'utf8');

const oldTicket = `                        IconButton(
                          icon: const Icon(
                            IconlyLight.ticket,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            context.push('/gala-ticket');
                          },
                        ),`;

const newCalendar = `                        // F3: Bouton calendrier anniversaires (remplace le ticket)
                        IconButton(
                          icon: const Icon(
                            Icons.cake_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            context.push('/birthday-calendar');
                          },
                          tooltip: 'Calendrier & Anniversaires',
                        ),`;

pc = tryReplace(pc, oldTicket, newCalendar, 'F3-profile-ticket-swap');
fs.writeFileSync(profileFile, pc, 'utf8');
console.log('user_profile_widget.dart updated');

// ─── F3b: Afficher birthday sur le profil public ───
const pubFile = 'lib/pages/new_pages/public_profile/public_profile_page.dart';
let pp = fs.readFileSync(pubFile, 'utf8');

// On cherche où lire les données du profil (load method) pour ajouter birthday
const oldLoad = `'bio': data['bio'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
        }`;

const newLoad = `'bio': data['bio'] ?? '',
          'isOnline': data['isOnline'] ?? false,
          'lastSeen': data['lastSeen'],
          'birthday': data['birthday'],  // F3: anniversaire
        }`;

pp = tryReplace(pp, oldLoad, newLoad, 'F3-public-birthday-data');

// Ajouter l'affichage birthday sous le statut de présence (après la section isOnline)
const oldBioSection = `                  if (bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        bio,
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),`;

const newBioSection = `                  // F3: affichage de l'anniversaire de l'ami sur son profil public
                  if (_friendshipStatus == FriendshipStatus.friends) Builder(builder: (ctx) {
                    final b = _profile?['birthday'] as Map<String, dynamic>?;
                    if (b == null) return const SizedBox.shrink();
                    const months = ['', 'jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
                    final now = DateTime.now();
                    final day = (b['day'] as num).toInt();
                    final month = (b['month'] as num).toInt();
                    final isToday = now.day == day && now.month == month;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(isToday ? '🎂' : '🎁', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            isToday ? 'C\'est son anniversaire aujourd\'hui !' : 'Anniv: $day \${months[month]}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isToday ? const Color(0xFFEC4899) : Colors.white54,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (bio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        bio,
                        style: GoogleFonts.outfit(fontSize: 13, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),`;

pp = tryReplace(pp, oldBioSection, newBioSection, 'F3-public-birthday-ui');
fs.writeFileSync(pubFile, pp, 'utf8');
console.log('public_profile_page.dart updated');

console.log('F3 swap + birthday UI done');
