"""
Configuration officielle de la Taxonomie DORÕN.
15 Grandes Catégories x 6-8 Sous-Catégories = ~100 Sous-catégories exhaustives.
"""

SUBCATEGORIES_BY_CATEGORY = {
    # 1. Tech & Connecté
    "cat_tech": [
        "subcat_smartphones_tablettes",
        "subcat_ordinateurs_accessoires",
        "subcat_audio",
        "subcat_wearables",
        "subcat_photo_video",
        "subcat_maison_connectee",
        "subcat_accessoires_auto_tech",
        "subcat_gadgets_divers",
    ],
    # 2. Mode & Style
    "cat_mode": [
        "subcat_vetements_femme",
        "subcat_vetements_homme",
        "subcat_chaussures",
        "subcat_sacs_maroquinerie",
        "subcat_bijoux",
        "subcat_montres_classiques",
        "subcat_accessoires_mode",
        "subcat_lingerie_nuit",
        "subcat_sportswear_outdoor",
    ],
    # 3. Maison & Intérieur
    "cat_maison": [
        "subcat_deco_murale_objets",
        "subcat_linge_maison",
        "subcat_cuisine_arts_de_la_table",
        "subcat_ambiance_bougies_senteurs",
        "subcat_rangement_organisation",
        "subcat_electromenager",
        "subcat_luminaire_ambiance",
    ],
    # 4. Beauté & Soins
    "cat_beaute": [
        "subcat_parfum",
        "subcat_soin_visage",
        "subcat_soin_corps",
        "subcat_maquillage",
        "subcat_cheveux_coiffure",
        "subcat_rasage_barbe",
        "subcat_appareils_beaute",
    ],
    # 5. Gastronomie & Saveurs
    "cat_food": [
        "subcat_epicerie_fine",
        "subcat_vins_spiritueux",
        "subcat_chocolats_confiseries",
        "subcat_cafe_the",
        "subcat_coffrets_degustation",
        "subcat_accessoires_sommellerie_bar",
    ],
    # 6. Sport & Performance
    "cat_sport": [
        "subcat_running_athletisme",
        "subcat_fitness_musculation",
        "subcat_sports_outdoor_rando",
        "subcat_sports_raquette",
        "subcat_sports_glisse_eau",
        "subcat_nutrition_recuperation_sport",
        "subcat_vetements_techniques_sport",
    ],
    # 7. Art & Créativité
    "cat_art": [
        "subcat_peinture_dessin",
        "subcat_sculpture_modelage",
        "subcat_loisirs_creatifs_diy",
        "subcat_livres_art_monographies",
        "subcat_affiches_tirages_dart",
        "subcat_materiel_arts_graphiques",
    ],
    # 8. Lecture & Univers Littéraire
    "cat_lecture": [
        "subcat_romans_litterature",
        "subcat_bd_romans_graphiques",
        "subcat_mangas_comics",
        "subcat_developpement_personnel_essais",
        "subcat_liseuses_accessoires_lecture",
        "subcat_beaux_livres_coffee_table",
    ],
    # 9. Voyage & Évasion
    "cat_voyage": [
        "subcat_valises_bagagerie",
        "subcat_sacs_a_dos_voyage",
        "subcat_accessoires_nomades",
        "subcat_organisation_bagages",
        "subcat_equipement_bivouac_aventure",
        "subcat_guides_carnets_voyage",
    ],
    # 10. Jeux Vidéo & Gaming
    "cat_jeuxvideo": [
        "subcat_consoles_gaming",
        "subcat_manettes_accessoires_gaming",
        "subcat_casques_audio_gaming",
        "subcat_jeux_video_hits",
        "subcat_fauteuils_mobilier_gaming",
        "subcat_goodies_figurines_gaming",
    ],
    # 11. Musique & Instruments
    "cat_musique": [
        "subcat_instruments_cordes",
        "subcat_claviers_pianos",
        "subcat_platines_vinyles",
        "subcat_home_studio_mao",
        "subcat_accessoires_musiciens",
        "subcat_percussions_batteries",
    ],
    # 12. Jardin & Nature
    "cat_jardinage": [
        "subcat_plantes_interieur_cache_pots",
        "subcat_potager_interieur_connecte",
        "subcat_outils_jardinage_ergonomiques",
        "subcat_graines_kits_plantation",
        "subcat_mobilier_deco_jardin",
        "subcat_arrosage_entretien_plantes",
    ],
    # 13. Bien-être & Relaxation
    "cat_bienetre": [
        "subcat_massages_relaxation",
        "subcat_yoga_meditation",
        "subcat_sommeil_reveils_lumiere",
        "subcat_aromatherapie_diffuseurs",
        "subcat_bains_thalasso_maison",
        "subcat_thermotherapie_acupression",
    ],
    # 14. Mécanique & Automobile
    "cat_mecanique_auto": [
        "subcat_accessoires_auto_interieur",
        "subcat_entretien_nettoyage_auto_prestige",
        "subcat_outils_mecanique_diagnostic",
        "subcat_dashcam_securite_auto",
        "subcat_lifestyle_passion_automobile",
        "subcat_accessoires_moto_motard",
    ],
    # 15. Aéronautique & Aviation
    "cat_aeronautique": [
        "subcat_drones_prises_de_vue",
        "subcat_maquettes_avions_collection",
        "subcat_simulation_vol_pilotage",
        "subcat_livres_histoire_aviation",
        "subcat_accessoires_lifestyle_aviateur",
        "subcat_astronomie_espace",
    ],
}

QUERY_TERM_BY_SUBCATEGORY = {
    # Tech
    "subcat_smartphones_tablettes": "smartphone",
    "subcat_ordinateurs_accessoires": "ordinateur portable",
    "subcat_audio": "écouteurs",
    "subcat_wearables": "montre connectée",
    "subcat_photo_video": "appareil photo",
    "subcat_maison_connectee": "enceinte connectée",
    "subcat_accessoires_auto_tech": "accessoire auto connecté",
    "subcat_gadgets_divers": "gadget high-tech",
    # Mode
    "subcat_vetements_femme": "robe",
    "subcat_vetements_homme": "pull homme",
    "subcat_chaussures": "chaussures",
    "subcat_sacs_maroquinerie": "sac à main",
    "subcat_bijoux": "bijou",
    "subcat_montres_classiques": "montre",
    "subcat_accessoires_mode": "ceinture",
    "subcat_lingerie_nuit": "lingerie",
    "subcat_sportswear_outdoor": "vêtement sport",
    # Maison
    "subcat_deco_murale_objets": "cadre décoratif",
    "subcat_linge_maison": "plaid",
    "subcat_cuisine_arts_de_la_table": "vaisselle",
    "subcat_ambiance_bougies_senteurs": "bougie parfumée",
    "subcat_rangement_organisation": "boîte de rangement",
    "subcat_electromenager": "cafetière",
    "subcat_luminaire_ambiance": "lampe design",
    # Beauté
    "subcat_parfum": "parfum",
    "subcat_soin_visage": "crème visage",
    "subcat_soin_corps": "soin corps",
    "subcat_maquillage": "palette maquillage",
    "subcat_cheveux_coiffure": "lisseur cheveux",
    "subcat_rasage_barbe": "tondeuse barbe",
    "subcat_appareils_beaute": "brosse nettoyante visage",
    # Food
    "subcat_epicerie_fine": "coffret gourmand",
    "subcat_vins_spiritueux": "coffret vin",
    "subcat_chocolats_confiseries": "chocolats",
    "subcat_cafe_the": "coffret thé",
    "subcat_coffrets_degustation": "coffret dégustation",
    "subcat_accessoires_sommellerie_bar": "accessoire vin sommelier",
    # Sport
    "subcat_running_athletisme": "chaussures running",
    "subcat_fitness_musculation": "matériel fitness musculation",
    "subcat_sports_outdoor_rando": "sac randonnée outdoor",
    "subcat_sports_raquette": "raquette tennis",
    "subcat_sports_glisse_eau": "accessoire glisse natation",
    "subcat_nutrition_recuperation_sport": "pistolet massage sport",
    "subcat_vetements_techniques_sport": "tenue sport technique",
    # Art
    "subcat_peinture_dessin": "coffret peinture dessin",
    "subcat_sculpture_modelage": "kit modelage céramique",
    "subcat_loisirs_creatifs_diy": "kit loisirs créatifs diy",
    "subcat_livres_art_monographies": "beau livre art taschen",
    "subcat_affiches_tirages_dart": "affiche art sérigraphie",
    "subcat_materiel_arts_graphiques": "tablette graphique dessin",
    # Lecture
    "subcat_romans_litterature": "roman best-seller littérature",
    "subcat_bd_romans_graphiques": "bande dessinée roman graphique",
    "subcat_mangas_comics": "coffret manga comics",
    "subcat_developpement_personnel_essais": "livre développement personnel",
    "subcat_liseuses_accessoires_lecture": "liseuse électronique",
    "subcat_beaux_livres_coffee_table": "beau livre coffee table",
    # Voyage
    "subcat_valises_bagagerie": "valise cabine voyage",
    "subcat_sacs_a_dos_voyage": "sac à dos voyage",
    "subcat_accessoires_nomades": "accessoire voyage nomade",
    "subcat_organisation_bagages": "organisateur bagage valise",
    "subcat_equipement_bivouac_aventure": "équipement bivouac aventure",
    "subcat_guides_carnets_voyage": "carnet voyage cuir",
    # Jeux Vidéo
    "subcat_consoles_gaming": "console jeux vidéo",
    "subcat_manettes_accessoires_gaming": "manette sans fil gaming",
    "subcat_casques_audio_gaming": "casque audio gaming",
    "subcat_jeux_video_hits": "jeu vidéo ps5 switch",
    "subcat_fauteuils_mobilier_gaming": "chaise fauteuil gaming",
    "subcat_goodies_figurines_gaming": "figurine collector gaming",
    # Musique
    "subcat_instruments_cordes": "guitare acoustique",
    "subcat_claviers_pianos": "piano numérique clavier",
    "subcat_platines_vinyles": "platine vinyle hifi",
    "subcat_home_studio_mao": "microphone home studio",
    "subcat_accessoires_musiciens": "accessoire musique guitare",
    "subcat_percussions_batteries": "cajon batterie électronique",
    # Jardinage
    "subcat_plantes_interieur_cache_pots": "plante intérieur pot céramique",
    "subcat_potager_interieur_connecte": "potager intérieur autonome",
    "subcat_outils_jardinage_ergonomiques": "outils jardinage inox",
    "subcat_graines_kits_plantation": "kit graines aromatiques bio",
    "subcat_mobilier_deco_jardin": "déco jardin braséro",
    "subcat_arrosage_entretien_plantes": "arrosoir design cuivre",
    # Bien-être
    "subcat_massages_relaxation": "appareil massage shiatsu",
    "subcat_yoga_meditation": "tapis yoga liège",
    "subcat_sommeil_reveils_lumiere": "simulateur aube sommeil",
    "subcat_aromatherapie_diffuseurs": "diffuseur huiles essentielles",
    "subcat_bains_thalasso_maison": "plateau bain relaxation",
    "subcat_thermotherapie_acupression": "tapis acupression relaxation",
    # Mécanique & Auto
    "subcat_accessoires_auto_interieur": "accessoire voiture intérieur",
    "subcat_entretien_nettoyage_auto_prestige": "kit nettoyage detailing auto",
    "subcat_outils_mecanique_diagnostic": "valise diagnostic auto",
    "subcat_dashcam_securite_auto": "dashcam voiture sécurité",
    "subcat_lifestyle_passion_automobile": "livre passion automobile",
    "subcat_accessoires_moto_motard": "support smartphone moto",
    # Aéronautique & Espace
    "subcat_drones_prises_de_vue": "drone caméra dji",
    "subcat_maquettes_avions_collection": "maquette avion métal collection",
    "subcat_simulation_vol_pilotage": "joystick simulateur vol",
    "subcat_livres_histoire_aviation": "beau livre aviation",
    "subcat_accessoires_lifestyle_aviateur": "lunettes aviateur soleil",
    "subcat_astronomie_espace": "télescope astronomie espace",
}

def build_queries(brand_subcategories: dict) -> list:
    queries = []
    for brand, subcats in brand_subcategories.items():
        for subcat in subcats:
            term = QUERY_TERM_BY_SUBCATEGORY.get(subcat)
            if not term:
                continue
            queries.append({
                "brand": brand,
                "subcategory": subcat,
                "query": f"{brand} {term}",
            })
    return queries
