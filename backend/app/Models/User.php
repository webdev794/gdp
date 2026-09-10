<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'phone', 'stripe_customer_id'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public function cart(): HasOne
    {
        return $this->hasOne(Cart::class);
    }

    public function addresses(): HasMany
    {
        return $this->hasMany(Address::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function supportThreads(): HasMany
    {
        return $this->hasMany(SupportThread::class);
    }

    /** Orders this user is the delivery rider for. */
    public function deliveries(): HasMany
    {
        return $this->hasMany(Order::class, 'delivery_partner_id');
    }

    /** Customer reviews of this user as a delivery rider. */
    public function riderReviews(): HasMany
    {
        return $this->hasMany(RiderReview::class, 'rider_id');
    }

    /** Refresh the denormalised rider rating from the reviews. */
    public function recomputeRiderRating(): void
    {
        $agg = $this->riderReviews()->selectRaw('avg(rating) as a, count(*) as c')->first();
        $this->forceFill([
            'rider_rating_avg' => $agg->c ? round((float) $agg->a, 2) : null,
            'rider_rating_count' => (int) $agg->c,
        ])->save();
    }

    /** Stores this rider serves (auto-assignment only considers these). */
    public function stores(): BelongsToMany
    {
        return $this->belongsToMany(Store::class, 'rider_store');
    }

    /**
     * The rider's position for "nearest rider" maths: the live fix when it's
     * fresh (pinged within 15 min), otherwise the admin-set base. Null when we
     * have neither.
     *
     * @return array{lat: float, lng: float, source: 'live'|'base'}|null
     */
    public function riderLocation(): ?array
    {
        $fresh = $this->rider_last_located_at
            && $this->rider_last_located_at->gt(now()->subMinutes(15));

        if ($fresh && $this->rider_last_lat !== null && $this->rider_last_lng !== null) {
            return ['lat' => (float) $this->rider_last_lat, 'lng' => (float) $this->rider_last_lng, 'source' => 'live'];
        }

        if ($this->rider_base_lat !== null && $this->rider_base_lng !== null) {
            return ['lat' => (float) $this->rider_base_lat, 'lng' => (float) $this->rider_base_lng, 'source' => 'base'];
        }

        return null;
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_admin' => 'boolean',
            'is_rider' => 'boolean',
            'rider_is_active' => 'boolean',
            'rider_rating_avg' => 'float',
            'rider_rating_count' => 'integer',
            'rider_declined_count' => 'integer',
            'rider_missed_count' => 'integer',
            'rider_base_lat' => 'float',
            'rider_base_lng' => 'float',
            'rider_last_lat' => 'float',
            'rider_last_lng' => 'float',
            'rider_last_located_at' => 'datetime',
        ];
    }
}
