<?php

namespace App\Controller;

use App\Entity\Game;
use App\Repository\GameRepository;
use Doctrine\ORM\EntityManagerInterface;
use Nelmio\ApiDocBundle\Attribute\Model;
use OpenApi\Attributes as OA;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Attribute\MapRequestPayload;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\HttpKernel\Exception\UnprocessableEntityHttpException;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Routing\Requirement\Requirement;
use Symfony\Component\Serializer\Exception\ExceptionInterface as SerializerException;
use Symfony\Component\Serializer\Normalizer\AbstractNormalizer;
use Symfony\Component\Serializer\SerializerInterface;
use Symfony\Component\Validator\Exception\ValidationFailedException;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/**
 * API REST « faite main » pour les jeux — EXEMPLE COMMENTÉ, à lire puis à imiter pour Team et Player.
 *
 *   GET    /api/games        liste des jeux
 *   GET    /api/games/{id}   un jeu                         (404 s'il n'existe pas)
 *   POST   /api/games        créer un jeu                   (201 + en-tête Location, 422 si invalide)
 *   PATCH  /api/games/{id}   modifier une partie des champs (422 si invalide)
 *   DELETE /api/games/{id}   supprimer                      (204, sans contenu)
 *
 * Le #[Route] de la classe s'applique à toutes les méthodes :
 *   - préfixe d'URL « /api/games » et préfixe de nom de route « api_game_ » ;
 *   - format: 'json' → les erreurs (404, 422...) sont, elles aussi, renvoyées en JSON.
 *
 * Les attributs #[OA\...] (OpenApi) sont FACULTATIFS : ils enrichissent la Swagger UI (http://localhost:8000/api).
 * Sans eux, la route apparaît quand même, avec ce que Symfony sait d'elle (chemin, méthode, paramètres).
 */
#[Route('/api/games', name: 'api_game_', format: 'json')]
#[OA\Tag(name: 'Jeux', description: 'Exemple fourni : les jeux de la ligue')]
final class GameController extends AbstractController
{
    /**
     * Injection de dépendances : Symfony fournit automatiquement les services demandés
     * dans le constructeur (ou en argument d'une méthode de contrôleur) grâce à leur type.
     */
    public function __construct(private readonly EntityManagerInterface $em)
    {
    }

    /** GET /api/games → 200 + tableau JSON. */
    #[Route('', name: 'list', methods: ['GET'])]
    public function list(GameRepository $games): JsonResponse
    {
        // findBy(critères, tri) : SELECT * FROM game ORDER BY name ASC
        $list = $games->findBy([], ['name' => 'ASC']);

        // $this->json() transforme les objets en JSON (composant Serializer) : un champ par getter.
        return $this->json($list);
    }

    /**
     * GET /api/games/{id} → 200, ou 404 si le jeu n'existe pas.
     *
     * Le paramètre « Game $game » est rempli automatiquement : Symfony lit {id} dans l'URL
     * et charge le jeu en base (EntityValueResolver). S'il n'existe pas → 404, sans une ligne de code.
     * La « requirement » DIGITS refuse /api/games/abc (404 aussi : aucune route ne correspond).
     */
    #[Route('/{id}', name: 'show', requirements: ['id' => Requirement::DIGITS], methods: ['GET'])]
    #[OA\Response(response: 200, description: 'Le jeu demandé', content: new Model(type: Game::class))]
    #[OA\Response(response: 404, description: 'Aucun jeu avec cet identifiant')]
    public function show(Game $game): JsonResponse
    {
        return $this->json($game);
    }

    /**
     * POST /api/games → 201 + Location, 422 si invalide, 415 si le corps n'est pas du JSON.
     *
     * #[MapRequestPayload] fait 3 choses avant même d'entrer dans la méthode :
     *   1. vérifie le Content-Type (application/json attendu, sinon 415) ;
     *   2. transforme le JSON en objet Game (désérialisation ; un « id » envoyé est ignoré : pas de setId()) ;
     *   3. valide l'objet avec les contraintes #[Assert\...] de l'entité → 422 + liste des erreurs.
     */
    #[Route('', name: 'create', methods: ['POST'])]
    #[OA\Response(response: 201, description: 'Jeu créé ; son URL est dans l\'en-tête Location')]
    #[OA\Response(response: 422, description: 'Données invalides : la liste des violations est dans la réponse')]
    public function create(#[MapRequestPayload] Game $game): JsonResponse
    {
        $this->em->persist($game); // « à enregistrer »...
        $this->em->flush();        // ... INSERT exécuté ici (l'id est alors connu)

        return $this->json($game, Response::HTTP_CREATED, [
            // Bonne pratique REST : l'URL de la ressource créée
            'Location' => $this->generateUrl('api_game_show', ['id' => $game->getId()]),
        ]);
    }

    /**
     * PATCH /api/games/{id} → 200, 400 si le JSON est illisible, 422 si le résultat est invalide.
     *
     * Ici on ne crée pas un objet : on COMPLÈTE l'objet existant avec les champs reçus
     * (option OBJECT_TO_POPULATE du Serializer), puis on le valide nous-mêmes.
     */
    #[Route('/{id}', name: 'update', requirements: ['id' => Requirement::DIGITS], methods: ['PATCH'])]
    public function update(Game $game, Request $request, SerializerInterface $serializer, ValidatorInterface $validator): JsonResponse
    {
        try {
            $serializer->deserialize($request->getContent(), Game::class, 'json', [
                AbstractNormalizer::OBJECT_TO_POPULATE => $game,
            ]);
        } catch (SerializerException $e) {
            throw new BadRequestHttpException('Corps de requête invalide : '.$e->getMessage(), $e);
        }

        $violations = $validator->validate($game);
        if (\count($violations) > 0) {
            // Même format d'erreur que #[MapRequestPayload] : 422 + liste des violations
            throw new UnprocessableEntityHttpException((string) $violations, new ValidationFailedException($game, $violations));
        }

        $this->em->flush(); // UPDATE (Doctrine sait déjà que l'objet a changé)

        return $this->json($game);
    }

    /** DELETE /api/games/{id} → 204 No Content. */
    #[Route('/{id}', name: 'delete', requirements: ['id' => Requirement::DIGITS], methods: ['DELETE'])]
    public function delete(Game $game): Response
    {
        $this->em->remove($game);
        $this->em->flush();

        return new Response(null, Response::HTTP_NO_CONTENT);
    }
}
