package by.fintrack.security;

import by.fintrack.entity.User;
import by.fintrack.repository.UserRepository;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.*;
import java.util.stream.Collectors;

@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String secret;

    @Value("${jwt.expiration}")
    private long expiration;

    @Autowired
    private UserRepository userRepository;

    private SecretKey getSigningKey() {
        byte[] keyBytes = Decoders.BASE64.decode(secret);
        return Keys.hmacShaKeyFor(keyBytes);
    }


    public String generateToken(Authentication authentication) {
        String username = authentication.getName();

        User user = userRepository.findByUsername(username).orElse(null);
        Long tokenVersion = (user != null) ? user.getTokenVersion() : 0L;

        String currencyName = (user != null) ? user.getMainCurrency().name() : "BYN";
        String emailValue = (user != null) ? user.getEmail() : "";

        String authorities = authentication.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(","));

        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);

        return Jwts.builder()
                .subject(username)
                .claim("email", emailValue)
                .claim("roles", authorities)
                .claim("mainCurrency", currencyName)
                .claim("tokenVersion", tokenVersion)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    public String generateToken(User user) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + expiration);

        return Jwts.builder()
                .subject(user.getUsername())
                .claim("email", user.getEmail())
                .claim("mainCurrency", user.getMainCurrency().name())
                .claim("roles", "ROLE_USER")
                .claim("tokenVersion", user.getTokenVersion())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    public boolean validateToken(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            Long tokenVersionClaim = claims.get("tokenVersion", Long.class);
            if (tokenVersionClaim == null) {
                return false;
            }

            String username = claims.getSubject();
            User user = userRepository.findByUsername(username).orElse(null);

            if (user == null || !user.getTokenVersion().equals(tokenVersionClaim)) {
                return false;
            }

            return true;
        } catch (JwtException | IllegalArgumentException e) {
            return false;
        }
    }

    public Authentication getAuthentication(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        String username = claims.getSubject();
        String rolesClaim = claims.get("roles", String.class);

        Collection<? extends GrantedAuthority> authorities = rolesClaim == null || rolesClaim.isEmpty()
                ? Collections.emptyList()
                : Arrays.stream(rolesClaim.split(","))
                  .filter(role -> !role.isBlank())
                  .map(role -> new SimpleGrantedAuthority(role.trim()))
                  .collect(Collectors.toList());

        UserDetails userDetails = org.springframework.security.core.userdetails.User.builder()
                .username(username)
                .password("")
                .authorities(authorities)
                .build();

        return new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(
                userDetails, null, authorities);
    }

    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.getSubject();
    }

    public String getMainCurrencyFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
        return claims.get("mainCurrency", String.class);
    }
}