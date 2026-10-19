<?php

namespace App\Controller;

use App\Dto\PlayerInput;
use App\Entity\Player;
use App\Repository\PlayerRepository;
use App\Repository\TeamRepository;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Attribute\MapRequestPayload;
use Symfony\Component\Routing\Attribute\Route;
use OpenApi\Attributes as OA;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api/players', name: 'api_player_', format: 'json')]
#[OA\Tag(name: 'Players', description: 'Things about players.')]
final class PlayerController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $em,
        private readonly TeamRepository         $teams,         // pour retrouver l'équipe à partir de son id
        private readonly ValidatorInterface     $validator, // pour valider l'entité une fois remplie
    )
    {
    }

    #[Route('', name: 'create', methods: ['POST'])]
    public function create(#[MapRequestPayload] PlayerInput $input): JsonResponse
    {
        $player = $this->apply(new Player(), $input);
        // À vous : persist, flush, 201 + Location (groupe player:read)
    }

    private function apply(Player $player, PlayerInput $input): Player
    {
        // 1. recopier le DTO dans l'entité : $player->setNickname($input->nickname)->setCountry(…)…
        // 2. si $input->team n'est pas null : $this->teams->find($input->team) ; introuvable → 422 sur « team »
        // 3. $player->setTeam($team) (null = agent libre)
        // 4. valider l'entité : $this->validator->validate($player) ; des violations → 422
        return $player;
    }
}
