package com.example.order_api_tuning.member.domain.repository;

import com.example.order_api_tuning.member.domain.entity.Member;
import java.util.Optional;

public interface MemberRepository {

  Optional<Member> findById(Long aLong);
}
