<?php

namespace App\Support;

use App\Models\RiderShift;
use App\Models\User;
use Illuminate\Support\Carbon;

/**
 * Reads a rider's shift ledger into the shapes the rider dashboard and the admin
 * console need: the live clock state, and a day-by-day attendance summary.
 */
final class RiderAttendance
{
    /** Fallback "full day" target when a rider has no per-rider target set. */
    public const DEFAULT_TARGET_MINUTES = 480;

    /** The live shift/availability state for a single rider. */
    public static function state(User $rider): array
    {
        $shift = $rider->currentShift();
        $break = $shift?->breaks->firstWhere('ended_at', null);

        $status = match (true) {
            ! $rider->rider_is_active => 'off_roster',
            $shift && $break => 'on_break',
            $shift && $rider->rider_available => 'clocked_in',
            $shift => 'paused',            // clocked in but held offline (admin or self)
            default => 'off',
        };

        return [
            'status' => $status,
            'available' => (bool) $rider->rider_available,
            'clocked_in' => (bool) $shift,
            'on_break' => (bool) $break,
            'clock_in_at' => $shift?->clock_in_at,
            'break_since' => $break?->started_at,
            'break_reason' => $break?->reason,
            'unavailable_reason' => $rider->rider_unavailable_reason,
            'today_worked_minutes' => self::workedMinutesBetween($rider, today(), today()->copy()->endOfDay()),
            'week_worked_minutes' => self::workedMinutesBetween($rider, today()->copy()->subDays(6), today()->copy()->endOfDay()),
        ];
    }

    /**
     * One row per calendar day the rider had a shift, newest first, over the last
     * $days days: first in, last out, net worked minutes, break minutes.
     *
     * @return list<array<string, mixed>>
     */
    public static function summary(User $rider, int $days = 14): array
    {
        $from = today()->copy()->subDays($days - 1);

        $shifts = $rider->riderShifts()
            ->where('clock_in_at', '>=', $from)
            ->with('breaks')
            ->orderByDesc('clock_in_at')
            ->get();

        return $shifts
            ->groupBy(fn (RiderShift $s) => $s->clock_in_at->toDateString())
            ->map(fn ($group, $date) => [
                'date' => $date,
                'first_in' => $group->min('clock_in_at'),
                'last_out' => $group->contains(fn ($s) => $s->clock_out_at === null)
                    ? null
                    : $group->max('clock_out_at'),
                'worked_minutes' => (int) $group->sum(fn (RiderShift $s) => $s->workedMinutes()),
                'break_minutes' => (int) $group->sum(fn (RiderShift $s) => $s->breakMinutes()),
                'shifts' => $group->count(),
            ])
            ->values()
            ->all();
    }

    /**
     * A full attendance report for one rider across an arbitrary date range
     * (e.g. a calendar month): every day in the window is present, classified as
     * `full` (worked >= target), `short` (worked some, under target) or `off`
     * (no shift), plus roll-up totals. Days after today are not included.
     */
    public static function report(User $rider, Carbon $from, Carbon $to): array
    {
        $from = $from->copy()->startOfDay();
        $to = min($to->copy()->endOfDay(), today()->copy()->endOfDay());
        $target = $rider->rider_daily_target_minutes ?: self::DEFAULT_TARGET_MINUTES;

        $byDay = $rider->riderShifts()
            ->whereBetween('clock_in_at', [$from, $to])
            ->with('breaks')
            ->get()
            ->groupBy(fn (RiderShift $s) => $s->clock_in_at->toDateString());

        $days = [];
        $sumFull = $sumShort = $sumOff = $sumWorked = $sumBreak = 0;

        for ($d = $from->copy(); $d->lte($to); $d->addDay()) {
            $key = $d->toDateString();
            $group = $byDay->get($key);

            $worked = $group ? (int) $group->sum(fn (RiderShift $s) => $s->workedMinutes()) : 0;
            $break = $group ? (int) $group->sum(fn (RiderShift $s) => $s->breakMinutes()) : 0;

            $status = match (true) {
                ! $group => 'off',
                $worked >= $target => 'full',
                default => 'short',
            };

            $status === 'full' ? $sumFull++ : ($status === 'short' ? $sumShort++ : $sumOff++);
            $sumWorked += $worked;
            $sumBreak += $break;

            $days[] = [
                'date' => $key,
                'weekday' => $d->dayOfWeekIso,           // 1 Mon .. 7 Sun
                'status' => $status,
                'worked_minutes' => $worked,
                'break_minutes' => $break,
                'first_in' => $group?->min('clock_in_at'),
                'last_out' => $group && ! $group->contains(fn ($s) => $s->clock_out_at === null)
                    ? $group->max('clock_out_at')
                    : null,
                'shifts' => $group?->count() ?? 0,
            ];
        }

        $activeDays = $sumFull + $sumShort;

        return [
            'from' => $from->toDateString(),
            'to' => $to->toDateString(),
            'target_minutes' => $target,
            'summary' => [
                'days_full' => $sumFull,
                'days_short' => $sumShort,
                'days_off' => $sumOff,
                'total_worked_minutes' => $sumWorked,
                'total_break_minutes' => $sumBreak,
                'avg_worked_minutes' => $activeDays ? (int) round($sumWorked / $activeDays) : 0,
            ],
            'days' => array_reverse($days), // newest first
        ];
    }

    private static function workedMinutesBetween(User $rider, Carbon $from, Carbon $to): int
    {
        return (int) $rider->riderShifts()
            ->whereBetween('clock_in_at', [$from, $to])
            ->with('breaks')
            ->get()
            ->sum(fn (RiderShift $s) => $s->workedMinutes());
    }
}
