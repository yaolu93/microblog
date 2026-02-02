import sys
import pygame

# from alien_game import ship


def check_events(ship):
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            sys.exit()
        elif event.type == pygame.KEYDOWN:
            if event.key == pygame.K_RIGHT:
                print("I am clicking right")
                ship.moving_right = True
            elif event.key == pygame.K_LEFT:
                print("I am clicking left")
                ship.moving_left = True
        elif event.type == pygame.KEYUP:
            if event.key == pygame.K_RIGHT:
                ship.moving_right = False
            elif event.key == pygame.K_LEFT:
                ship.moving_left = False


def update_screen(ai_setting, screen, ship):
    screen.fill(ai_setting.bg_color)
    ship.update()
    ship.blitme()
    pygame.display.flip()
