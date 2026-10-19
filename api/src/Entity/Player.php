<?php

namespace App\Entity;

use App\Repository\PlayerRepository;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Nelmio\ApiDocBundle\TypeDescriber\IntegerDescriber;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[UniqueEntity('nickname', message: 'Ce pseudo est déjà pris.')]
#[ORM\Entity(repositoryClass: PlayerRepository::class)]
class Player
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['player:read'])]
    private ?int $id = null;

    #[ORM\Column(length: 30, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Length(min: 2, max: 30)]
    #[Groups(['player:read', 'player:write', 'team:read'])]
    private ?string $nickname = null;

    #[ORM\Column(length: 2)]
    #[Assert\NotBlank]
    #[Assert\Country]
    #[Groups(['player:read', 'player:write'])]
    private ?string $country = null;

    #[ORM\Column(length: 30, nullable: true)]
    #[Assert\Length(max: 30)]
    #[Groups(['player:read', 'player:write', 'team:read'])]
    private ?string $role = null;

    #[ORM\Column(type: Types::INTEGER, options: ['default' => 1000])]
    #[Assert\Range(min: 0, max: 3000)]
    #[Groups(['player:read', 'player:write', 'team:read'])]
    private ?int $rating = 1000;

    #[ORM\Column(nullable: true)]
    #[Assert\LessThan('-13 years', message: 'Un joueur doit avoir au moins 13 ans.')]
    #[Groups(['player:write'])]
    private ?\DateTimeImmutable $birthDate = null;

    #[ORM\ManyToOne(inversedBy: 'players')]
    #[ORM\JoinColumn(onDelete: 'SET NULL')]
    #[Groups(['player:read', 'player:write'])]
    private ?Team $team = null;

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getNickname(): ?string
    {
        return $this->nickname;
    }

    public function setNickname(string $nickname): static
    {
        $this->nickname = $nickname;

        return $this;
    }

    public function getCountry(): ?string
    {
        return $this->country;
    }

    public function setCountry(string $country): static
    {
        $this->country = $country;

        return $this;
    }

    public function getRole(): ?string
    {
        return $this->role;
    }

    public function setRole(?string $role): static
    {
        $this->role = $role;

        return $this;
    }

    public function getRating(): ?int
    {
        return $this->rating;
    }

    public function setRating(int $rating): static
    {
        $this->rating = $rating;

        return $this;
    }

    public function getBirthDate(): ?\DateTimeImmutable
    {
        return $this->birthDate;
    }

    public function setBirthDate(?\DateTimeImmutable $birthDate): static
    {
        $this->birthDate = $birthDate;

        return $this;
    }

    public function getTeam(): ?Team
    {
        return $this->team;
    }

    public function setTeam(?Team $team): static
    {
        $this->team = $team;

        return $this;
    }
}
