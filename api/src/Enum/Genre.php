<?php

namespace App\Enum;

/**
 * Genre d'un jeu vidéo compétitif.
 *
 * Un enum PHP « backed » (adossé à une chaîne) est rangé en base et renvoyé en JSON
 * par sa valeur ("moba", "fps"...). Une valeur inconnue dans une requête → 422.
 */
enum Genre: string
{
    case Moba = 'moba';
    case Fps = 'fps';
    case Fighting = 'fighting';
    case Sports = 'sports';
    case Racing = 'racing';
    case Strategy = 'strategy';
}
