package com.example.order_api_tuning.member.persistence;

import com.example.order_api_tuning.member.domain.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;

public interface JpaMemberRepository extends JpaRepository<Member, Long> {

}
