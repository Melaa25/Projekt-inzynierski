<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_is_built_from_first_letter_and_surname(): void
    {
        $this->assertSame('j.kowalski', User::buildLoginFromName('Jan Kowalski'));
    }

    public function test_polish_letters_are_replaced_in_login(): void
    {
        $this->assertSame('e.slusarczyk', User::buildLoginFromName('Ewa Ślusarczyk'));
        $this->assertSame('l.zolkiewski', User::buildLoginFromName('Łukasz Żółkiewski'));
    }

    public function test_next_number_is_added_when_login_is_taken(): void
    {
        User::factory()->create(['login' => 'j.kowalski']);
        User::factory()->create(['login' => 'j.kowalski2']);

        $this->assertSame('j.kowalski3', User::buildLoginFromName('Jan Kowalski'));
    }
}
