<?php

namespace App\Entity;

use App\Enum\Genre;
use App\Repository\GameRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Validator\Constraints as Assert;

/**
 * Un jeu vidéo pratiqué en compétition (Rocket League, Valorant...).
 *
 * EXEMPLE COMMENTÉ — une entité Doctrine « classique » :
 *   - #[ORM\...]    : le mapping vers la base de données (Doctrine) ;
 *   - #[Assert\...] : les règles de validation (Symfony Validator) → réponses 422.
 * Elle est exposée en HTTP, à la main, par src/Controller/GameController.php.
 */
#[ORM\Entity(repositoryClass: GameRepository::class)]
#[UniqueEntity('name', message: 'Ce jeu existe déjà.')]
class Game
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    private ?int $id = null;

    /** Nom du jeu (unique). */
    #[ORM\Column(length: 100, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Length(max: 100)]
    private ?string $name = null;

    /** Genre du jeu. */
    #[ORM\Column(enumType: Genre::class)]
    #[Assert\NotNull]
    private ?Genre $genre = null;

    /** Nombre de joueurs par équipe (1 pour un jeu de combat en 1 contre 1). */
    #[ORM\Column]
    #[Assert\NotNull]
    #[Assert\Range(min: 1, max: 10)]
    private ?int $teamSize = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getName(): ?string
    {
        return $this->name;
    }

    public function setName(string $name): static
    {
        $this->name = $name;

        return $this;
    }

    public function getGenre(): ?Genre
    {
        return $this->genre;
    }

    public function setGenre(Genre $genre): static
    {
        $this->genre = $genre;

        return $this;
    }

    public function getTeamSize(): ?int
    {
        return $this->teamSize;
    }

    public function setTeamSize(int $teamSize): static
    {
        $this->teamSize = $teamSize;

        return $this;
    }
}
