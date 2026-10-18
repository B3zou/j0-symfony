<?php

namespace App\DataFixtures;

use App\Entity\Game;
use App\Entity\Player;
use App\Entity\Team;
use App\Enum\Genre;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;

/**
 * Jeu de données de démonstration de la GG League (TP, étape 5).
 *
 * À copier dans api/src/DataFixtures/, puis : make db-reset
 * Les données sont fixes (pas d'aléatoire) : après « make db-reset », Null Pointers est toujours l'équipe n°1.
 * Demain, ce fichier s'enrichira des tournois et des matchs.
 */
class AppFixtures extends Fixture
{
    public function load(ObjectManager $manager): void
    {
        // ── Jeux ────────────────────────────────────────────────────────────
        foreach ([
            ['Rocket League', Genre::Sports, 3],
            ['Valorant', Genre::Fps, 5],
            ['League of Legends', Genre::Moba, 5],
            ['Street Fighter 6', Genre::Fighting, 1],
            ['Trackmania', Genre::Racing, 1],
        ] as [$name, $genre, $teamSize]) {
            $manager->persist((new Game())->setName($name)->setGenre($genre)->setTeamSize($teamSize));
        }

        // ── Équipes et joueurs (un roster de 3 pour Rocket League) ──────────
        $rosters = [
            ['Null Pointers', 'NUL', 'FR', [['Zer0Day', 'striker', 2450, 'FR'], ['Segv', 'playmaker', 2310, 'FR'], ['NaN', 'defender', 2280, 'BE']]],
            ['Kernel Panic', 'KPN', 'FR', [['Byt3', 'striker', 2390, 'FR'], ['Oops', 'playmaker', 2205, 'FR'], ['Sigkill', 'defender', 2350, 'CH']]],
            ['Lag Busters', 'LAG', 'BE', [['Ping', 'striker', 2150, 'BE'], ['Jitter', 'playmaker', 2080, 'BE'], ['Packet', 'defender', 2120, 'NL']]],
            ['Stack Overflowers', 'STK', 'CA', [['Recursion', 'striker', 2420, 'CA'], ['Heap', 'playmaker', 2290, 'CA'], ['Frame', 'defender', 2260, 'US']]],
            ['404 Not Found', '404', 'CH', [['NotHere', 'striker', 2190, 'CH'], ['Lost', 'playmaker', 2170, 'FR'], ['Void', 'defender', 2240, 'CH']]],
            ['Segfault Esports', 'SEG', 'DE', [['Coredump', 'striker', 2330, 'DE'], ['Dangling', 'playmaker', 2210, 'DE'], ['Nullptr', 'defender', 2300, 'AT']]],
            ['Sudo Squad', 'SDO', 'ES', [['Root', 'striker', 2270, 'ES'], ['Chmod', 'playmaker', 2140, 'ES'], ['Su', 'defender', 2160, 'PT']]],
            ['Merge Conflict', 'MRG', 'FR', [['Rebase', 'striker', 2360, 'FR'], ['Cherry', 'playmaker', 2250, 'FR'], ['Blame', 'defender', 2190, 'FR']]],
        ];
        foreach ($rosters as [$name, $tag, $country, $players]) {
            $team = (new Team())->setName($name)->setTag($tag)->setCountry($country);
            $manager->persist($team);
            foreach ($players as [$nickname, $role, $rating, $playerCountry]) {
                $player = (new Player())
                    ->setNickname($nickname)
                    ->setRole($role)
                    ->setRating($rating)
                    ->setCountry($playerCountry)
                    ->setBirthDate(new \DateTimeImmutable('2001-06-15'));
                $team->addPlayer($player);
                $manager->persist($player);
            }
        }

        // ── Agents libres (sans équipe) ─────────────────────────────────────
        foreach ([['Glitch', 2210, 'FR'], ['Lagger', 1500, 'BE']] as [$nickname, $rating, $country]) {
            $manager->persist((new Player())->setNickname($nickname)->setRating($rating)->setCountry($country));
        }

        $manager->flush();
    }
}
