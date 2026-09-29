<?php

namespace App\Support;

class PageTokens
{
    /**
     * Placeholders an admin can type into page text, filled from Store settings.
     *
     * @return array<string, string>
     */
    public static function values(): array
    {
        $branding = Branding::current();

        return [
            '{store_name}' => $branding['store_name'],
            '{email}' => $branding['contact_email'],
            '{phone}' => $branding['contact_phone'],
            '{address}' => $branding['contact_address'],
        ];
    }

    /**
     * Fill placeholders in a page's text. A line that uses a placeholder whose
     * setting is blank is dropped, so an unset phone or email never leaves a
     * dangling "Phone:" label behind.
     *
     * @param  array<string, string>  $values
     */
    public static function fill(string $text, array $values): string
    {
        if (! str_contains($text, '{')) {
            return $text;
        }

        $empty = array_keys(array_filter($values, fn ($value) => trim($value) === ''));
        if ($empty) {
            $lines = preg_split('/\r?\n/', $text);
            $lines = array_filter($lines, function ($line) use ($empty) {
                foreach ($empty as $token) {
                    if (str_contains($line, $token)) {
                        return false;
                    }
                }

                return true;
            });
            $text = preg_replace("/\n{3,}/", "\n\n", implode("\n", $lines));
            // A heading whose only lines were dropped would be left empty — drop it too.
            $text = trim(preg_replace('/^#{1,6} [^\n]*\n+(?=#{1,6} |\s*\z)/m', '', $text), "\n");
        }

        return strtr($text, $values);
    }

    /**
     * Fill every string inside a page's section blocks.
     *
     * @param  array<int|string, mixed>  $data
     * @param  array<string, string>  $values
     * @return array<int|string, mixed>
     */
    public static function fillArray(array $data, array $values): array
    {
        foreach ($data as $key => $value) {
            if (is_string($value)) {
                $data[$key] = self::fill($value, $values);
            } elseif (is_array($value)) {
                $data[$key] = self::fillArray($value, $values);
            }
        }

        return $data;
    }
}
