<?php

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use OpenApi\Attributes as OA;

#[Route('/api', format: 'json')]
#[OA\Tag(name: 'Ping', description: '..... Pong ?')]
final class PingController extends AbstractController
{
    #[Route('/ping', name: 'app_ping', methods: ['GET'])]
    public function index(): Response
    {
        return $this->json([
            'status' => 'ok',
            'league' => 'GG League'
        ]);
    }

    #[Route('/hello/{name}',
        name: 'app_hello',
        requirements: ['name' => '[a-zA-Z0-9_]{2,30}'],
        methods: ['GET']
    )]
    public function hello(string $name): Response
    {
        $return = 'GG ' . $name . ' !';
        return $this->json([
            'message' => $return,
        ]);
    }
}
