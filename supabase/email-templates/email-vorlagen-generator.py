# Erzeugt die Supabase-Mailvorlagen (supabase/email-templates/) und eine lokale
# Vorschau (supabase/email-templates/email-vorlagen-vorschau.html). Aufruf im Projektordner:
#   python3 supabase/email-templates/email-vorlagen-generator.py
# Layout: volle Breite (Balken von links nach rechts), Inhalt linksbündig.
# Logo: Canspot_Logo-main.png auf canspot.de (Strato, Ordner wp-content/Bilder-allgemein).
import os, html

OUT = 'supabase/email-templates'
SITE = 'https://canspotorga.github.io/canspotapp/'
FONT = 'Arial,Helvetica,sans-serif'
SLOGAN = 'Der Energy soll kicken. Nicht der Preis.'
# Logo liegt auf dem eigenen Strato-Webspace (canspot.de), nicht auf GitHub.
LOGO = 'https://canspot.de/wp-content/Bilder-allgemein/Canspot_Logo-main.png'
SPAM_TIP = ('Tipp: Damit unsere E-Mails nicht im Spam-Ordner landen, nimm den Absender '
            'in dein Adressbuch auf oder markiere diese E-Mail als „Kein Spam“.')


def wrap(heading, body_html, button=None, reason=''):
    btn = ''
    if button:
        label, url = button
        btn = f'''
<tr><td style="padding:8px 40px 0 40px;" align="left">
<table role="presentation" cellpadding="0" cellspacing="0" border="0"><tr>
<td style="background:#3363ac;border-radius:10px;">
<a href="{url}" style="display:inline-block;padding:14px 28px;font-family:{FONT};font-size:15px;font-weight:bold;color:#ffffff;text-decoration:none;border-radius:10px;">{label}</a>
</td></tr></table>
</td></tr>'''''
    return f'''<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>CanSpot</title>
</head>
<body style="margin:0;padding:0;background:#ffffff;">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="width:100%;background:#ffffff;">
<tr><td style="background:#1b213f;padding:22px 40px 20px 40px;" align="left">
<img src="{LOGO}" width="180" height="45" alt="CanSpot" style="display:block;border:0;outline:none;width:180px;height:45px;font-family:{FONT};font-size:26px;font-weight:bold;color:#ffffff;">
<div style="margin-top:12px;font-family:{FONT};font-size:15px;line-height:21px;font-weight:bold;color:#ffffff;">{SLOGAN}</div>
</td></tr>
<tr><td style="background:#3363ac;height:4px;line-height:4px;font-size:0;">&nbsp;</td></tr>
<tr><td style="padding:32px 40px 8px 40px;font-family:{FONT};font-size:22px;line-height:30px;font-weight:bold;color:#1b213f;" align="left">
{heading}
</td></tr>
<tr><td style="padding:4px 40px 16px 40px;font-family:{FONT};font-size:15px;line-height:24px;color:#1b213f;" align="left">
<div style="max-width:680px;">
{body_html}
</div>
</td></tr>{btn}
<tr><td style="padding:24px 40px 32px 40px;font-family:{FONT};font-size:13px;line-height:20px;color:#696c80;" align="left">
<div style="max-width:680px;">{SPAM_TIP}</div>
</td></tr>
<tr><td style="background:#f3f4f7;border-top:1px solid #dbdbe0;padding:20px 40px 24px 40px;font-family:{FONT};font-size:12px;line-height:18px;color:#696c80;" align="left">
<div style="max-width:680px;">{reason}<br><br>
<b style="color:#1b213f;">CanSpot</b> · <a href="{SITE}impressum.html" style="color:#696c80;">Impressum</a> · <a href="{SITE}datenschutz.html" style="color:#696c80;">Datenschutz</a></div>
</td></tr>
</table>
</body>
</html>
'''


P = 'style="margin:0 0 12px 0;"'
P_LAST = 'style="margin:0;"'

T = [
    ('1-confirm-signup.html', 'Confirm sign up',
     'Bitte bestätige deine E-Mail-Adresse für CanSpot',
     wrap('Willkommen bei CanSpot!',
          f'<p {P}>{{{{ if .Data.username }}}}Hallo {{{{ .Data.username }}}},{{{{ else }}}}Hallo,{{{{ end }}}}</p>'
          f'<p {P_LAST}>schön, dass du dabei bist. Bitte bestätige noch kurz deine E-Mail-Adresse, damit dein Konto aktiv wird.</p>',
          ('E-Mail-Adresse bestätigen', '{{ .ConfirmationURL }}'),
          reason='Du bekommst diese E-Mail, weil mit dieser Adresse ein CanSpot-Konto registriert wurde. '
                 'Warst du das nicht, kannst du die E-Mail einfach ignorieren. Ohne Bestätigung wird kein Konto aktiv.')),
    ('2-reset-password.html', 'Reset password',
     'Neues Passwort für dein CanSpot-Konto',
     wrap('Passwort zurücksetzen',
          f'<p {P}>Hallo,</p>'
          f'<p {P_LAST}>für dein CanSpot-Konto wurde ein neues Passwort angefordert. Über den Button kannst du jetzt ein neues Passwort festlegen.</p>',
          ('Neues Passwort festlegen', '{{ .ConfirmationURL }}'),
          reason='Du hast kein neues Passwort angefordert? Dann ignoriere diese E-Mail. Dein bisheriges Passwort bleibt gültig.')),
    ('3-change-email.html', 'Change email address',
     'Bitte bestätige deine neue E-Mail-Adresse für CanSpot',
     wrap('Neue E-Mail-Adresse bestätigen',
          f'<p {P}>Hallo,</p>'
          f'<p {P_LAST}>für dein CanSpot-Konto soll künftig die Adresse <b>{{{{ .NewEmail }}}}</b> verwendet werden. Bitte bestätige die Änderung.</p>',
          ('Änderung bestätigen', '{{ .ConfirmationURL }}'),
          reason='Du hast diese Änderung nicht angefordert? Dann ignoriere diese E-Mail. Deine bisherige Adresse bleibt bestehen.')),
    ('4-password-changed.html', 'Password changed (Security)',
     'Dein CanSpot-Passwort wurde geändert',
     wrap('Dein Passwort wurde geändert',
          f'<p {P}>Hallo,</p>'
          f'<p {P}>das Passwort für dein CanSpot-Konto ({{{{ .Email }}}}) wurde soeben geändert.</p>'
          f'<p {P_LAST}>Warst du das nicht? Dann setze in der App über <b>„Passwort vergessen?“</b> sofort ein neues Passwort und melde dich bei uns über die Kontaktadresse im Impressum.</p>',
          None,
          reason='Diese Sicherheitsmitteilung wird automatisch bei jeder Passwortänderung verschickt.')),
    ('5-email-changed.html', 'Email address changed (Security)',
     'Deine E-Mail-Adresse bei CanSpot wurde geändert',
     wrap('Deine E-Mail-Adresse wurde geändert',
          f'<p {P}>Hallo,</p>'
          f'<p {P}>die E-Mail-Adresse deines CanSpot-Kontos wurde von <b>{{{{ .OldEmail }}}}</b> auf <b>{{{{ .Email }}}}</b> geändert.</p>'
          f'<p {P_LAST}>Warst du das nicht? Dann melde dich bitte sofort über die Kontaktadresse im Impressum.</p>',
          None,
          reason='Diese Sicherheitsmitteilung wird automatisch bei jeder Änderung der E-Mail-Adresse verschickt.')),
]

for fn, _, _, body in T:
    open(os.path.join(OUT, fn), 'w', encoding='utf-8').write(body)

with open(os.path.join(OUT, 'BETREFF.txt'), 'w', encoding='utf-8') as f:
    f.write('Supabase -> Authentication -> Emails -> Templates\n'
            'Je Vorlage: Betreff (Subject) eintragen, HTML-Datei in "Message body" (Source) einfuegen.\n\n')
    for fn, name, subj, _ in T:
        f.write(f'{name}\n  Betreff: {subj}\n  Datei:   {fn}\n\n')

# Lokale Vorschau mit Beispielwerten, je Vorlage ein iframe in voller Breite.
prev = ['<!DOCTYPE html><html lang="de"><head><meta charset="utf-8"><title>CanSpot Mailvorlagen</title></head>'
        '<body style="margin:0;background:#d9dae0;font-family:Arial,sans-serif">']
for fn, name, subj, body in T:
    b = (body.replace('{{ if .Data.username }}Hallo {{ .Data.username }},{{ else }}Hallo,{{ end }}', 'Hallo Bri,')
         .replace('{{ .ConfirmationURL }}', 'https://beispiel-link')
         .replace('{{ .NewEmail }}', 'neu@beispiel.de').replace('{{ .OldEmail }}', 'alt@beispiel.de')
         .replace('{{ .Email }}', 'du@beispiel.de'))
    prev.append(f'<div style="padding:14px 16px 6px;font-size:13px;color:#333"><b>{html.escape(name)}</b> · Betreff: „{html.escape(subj)}“</div>'
                f'<iframe srcdoc="{html.escape(b, quote=True)}" style="display:block;width:100%;height:560px;border:0;background:#fff"></iframe>')
prev.append('</body></html>')
open(os.path.join(OUT, 'email-vorlagen-vorschau.html'), 'w', encoding='utf-8').write(''.join(prev))
print('ok')

