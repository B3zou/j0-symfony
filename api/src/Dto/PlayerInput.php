<?php

namespace App\Dto;

class PlayerInput
{
    public string $nickname = '';
    public string $country = '';
    public ?string $role = null;
    public int $rating = 1000;
    public ?\DateTimeImmutable $birthDate = null;   // format attendu : "2002-04-12"
    public ?int $team = null;                       // id de l'équipe, ou null pour un agent libre
}
